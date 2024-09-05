---@type LspUiModuleDiagnostic
---@diagnostic disable-next-line: missing-fields
local M = {}

M._util = {
  signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
    return vim.startswith(s.name, 'DiagnosticSign')
  end),
  active_wins = {},
}

function M.goto_next()
  local pos = vim.diagnostic.get_next_pos()

  if not pos then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end

  local diag = vim.fn.filter(
    vim.diagnostic.get(0, { lnum = pos[1] }),
    function(_, d)
      return d.col == pos[2]
    end
  )

  if #diag == 0 then
    vim.notify('No diagnostics at position', vim.log.levels.INFO)
    return
  end

  M:_open({ type = 'dir', diag = diag })
end

function M.goto_prev()
  local pos = vim.diagnostic.get_prev_pos()

  if not pos then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end

  local diag = vim.fn.filter(
    vim.diagnostic.get(0, { lnum = pos[1] }),
    function(_, d)
      return d.col == pos[2]
    end
  )

  if #diag == 0 then
    vim.notify('No diagnostics at position', vim.log.levels.INFO)
    return
  end

  M:_open({ type = 'dir', diag = diag })
end

function M.get_line()
  local pos = vim.fn.getcurpos()
  local diag = vim.diagnostic.get(0, { lnum = pos[2] - 1 })

  if #diag == 0 then
    vim.notify('No diagnostics at position', vim.log.levels.INFO)
    return
  end

  M:_open({ type = 'line', diag = diag })
end

function M:_preprocess(raw)
  local diag = raw.diag
  local tbl = {
    title = {},
    type = raw.type,
    diag = {},
  }

  for i = 1, #diag do
    tbl.diag[i] = {
      msg = {},
      src = diag[i].source,
      sev = diag[i].severity,
      ln = diag[i].lnum + 1,
      col = diag[i].col + 1,
      ecol = diag[i].end_col,
      vcol = diag[i].col + 1 < diag[i].end_col
          and diag[i].col + 1 .. '-' .. diag[i].end_col
        or diag[i].col + 1,
    }

    for ln in diag[i].message:gmatch('(.-)\r?\n') do
      table.insert(tbl.diag[i].msg, ln)
    end
    -- WARN: unstable use of character class
    table.insert(tbl.diag[i].msg, diag[i].message:match('[\r\n]*([^\r\n]*)$'))

    tbl.diag[i].msg[1] = self._util.signs[tbl.diag[i].sev].text
      .. tbl.diag[i].msg[1]
  end

  for i = 1, #tbl.diag do
    for j = 2, #tbl.diag[i].msg do
      tbl.diag[i].msg[j] = (' '):rep(
        vim.fn.strdisplaywidth(self._util.signs[tbl.diag[i].sev].text)
      ) .. tbl.diag[i].msg[j]
    end
  end

  if raw.type == 'dir' then
    tbl.title.icon = {
      ' ' .. self._util.signs[tbl.diag[1].sev].text,
      self._util.signs[tbl.diag[1].sev].texthl,
    }
  else
    local max_sev = vim
      .iter(tbl.diag)
      :map(function(d)
        return d.sev
      end)
      :fold(math.huge, function(min, i)
        if i < min then
          min = i
        end
        return min
      end)

    tbl.title.icon = {
      ' ' .. self._util.signs[max_sev].text,
      self._util.signs[max_sev].texthl,
    }
  end

  tbl.title.loc = (
    raw.type == 'line' and tbl.diag[1].ln
    or tbl.diag[1].ln .. ':' .. tbl.diag[1].vcol
  ) .. ' '

  return tbl
end

function M:_format(proc)
  local tbl = {}

  for i = 1, #proc.diag do
    for j = 1, #proc.diag[i].msg do
      table.insert(tbl, proc.diag[i].msg[j])
    end

    tbl[#tbl] = tbl[#tbl]
      .. ' '
      .. (proc.type == 'dir' and proc.diag[i].src or proc.diag[i].vcol)
  end

  return tbl
end

function M:_set_highlights(bufnr, proc)
  local offset = -1

  for i = 1, #proc.diag do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      self._util.signs[proc.diag[i].sev].texthl,
      offset + i,
      0,
      vim.fn.byteidx(proc.diag[i].msg[1], 1)
    )
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      'NeutralFloat',
      offset + (#proc.diag[i].msg > 1 and #proc.diag[i].msg - 1 or 0) + i,
      proc.diag[i].msg[#proc.diag[i].msg]:len(),
      -1
    )

    if #proc.diag[i].msg > 1 then
      offset = offset + #proc.diag[i].msg - 1
    end
  end
end

function M:_open(raw)
  local proc = self:_preprocess(raw)
  local content = self:_format(proc)

  if proc.type == 'dir' then
    vim.cmd('mark`')
    vim.fn.cursor({ proc.diag[#proc.diag].ln, proc.diag[#proc.diag].col })
  end

  vim.iter(M._util.active_wins):each(function(w)
    L.win.close(w)
  end)
  M._util.active_wins = {}

  local data = L.win.open_cursor(content, false, {
    title = {
      proc.title.icon,
      { 'Diagnostics ', 'FloatTitle' },
      { proc.title.loc, 'NeutralFloat' },
    },
    focusable = false,
    zindex = 2,
    width = math.max(
      L.tbl.max_len(content),
      proc.title.icon[1]:len() + ('Diagnostics '):len() + proc.title.loc:len()
    ),
    noautocmd = true,
  })

  table.insert(M._util.active_wins, data.nwin)
  self:_set_highlights(data.nbuf, proc)

  -- TODO: WinScrolled - move window to new cursor position instead
  L.cmd.event(
    { 'BufLeave', 'CursorMoved', 'InsertEnter', 'WinScrolled' },
    data.obuf,
    function()
      L.win.close(data.nwin)
      M._util.active_wins = vim
        .iter(M._util.active_wins)
        :filter(function(w)
          return w ~= data.nwin
        end)
        :totable()
    end
  )
end

return M

---@type LspUiModuleDiagnostic
---@diagnostic disable-next-line: missing-fields
local M = {}

M._util = {
  signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
    return vim.startswith(s.name, 'DiagnosticSign')
  end),
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
  }

  for i = 1, #diag do
    tbl[i] = {
      data = {},
      src = vim.startswith(diag[i].source, 'Lua ') and 'lua_ls'
        or diag[i].source,
      sev = diag[i].severity,
      ln = diag[i].lnum + 1,
      col = diag[i].col + 1,
      ecol = diag[i].end_col,
      vcol = diag[i].col + 1 < diag[i].end_col
          and diag[i].col + 1 .. '-' .. diag[i].end_col
        or diag[i].col + 1,
    }

    for ln in diag[i].message:gmatch('(.-)\r?\n') do
      table.insert(tbl[i].data, ln)
    end
    -- WARN: unstable use of character class
    table.insert(tbl[i].data, diag[i].message:match('[\r\n]*([^\r\n]*)$'))

    tbl[i].data[1] = self._util.signs[tbl[i].sev].text .. tbl[i].data[1]
  end

  for i = 1, #tbl do
    for j = 2, #tbl[i].data do
      tbl[i].data[j] = (' '):rep(
        vim.fn.strdisplaywidth(self._util.signs[tbl[i].sev].text)
      ) .. tbl[i].data[j]
    end
  end

  tbl.title.icon = raw.type == 'line'
      and { ' ' .. self._util.signs[3].text, self._util.signs[3].texthl }
    or {
      ' ' .. self._util.signs[tbl[1].sev].text,
      self._util.signs[tbl[1].sev].texthl,
    }
  tbl.title.loc = (
    raw.type == 'line' and tbl[1].ln or tbl[1].ln .. ':' .. tbl[1].vcol
  ) .. ' '

  return tbl
end

function M:_format(proc)
  local tbl = {}

  for i = 1, #proc do
    for j = 1, #proc[i].data do
      table.insert(tbl, proc[i].data[j])
    end

    tbl[#tbl] = tbl[#tbl]
      .. ' '
      .. (proc.type == 'dir' and proc[i].src or proc[i].vcol)
  end

  return tbl
end

function M:_set_highlights(bufnr, proc)
  local offset = -1

  for i = 1, #proc do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      self._util.signs[proc[i].sev].texthl,
      offset + i,
      0,
      vim.fn.byteidx(proc[i].data[1], 1)
    )
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      'NeutralFloat',
      offset + (#proc[i].data > 1 and #proc[i].data - 1 or 0) + i,
      proc[i].data[#proc[i].data]:len(),
      -1
    )

    if #proc[i].data > 1 then
      offset = offset + #proc[i].data - 1
    end
  end
end

function M:_open(raw)
  local proc = self:_preprocess(raw)
  local content = self:_format(proc)

  if proc.type == 'dir' then
    vim.fn.cursor({ proc[#proc].ln, proc[#proc].col })
  end

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
  })

  self:_set_highlights(data.nbuf, proc)

  L.cmd.event(
    { 'BufLeave', 'CursorMoved', 'InsertEnter', 'WinNew' },
    data.obuf,
    function()
      L.win.close(data.nwin)
    end
  )
end

return M

---@class lsp.ui.Diagnostic : lsp.ui
local M = {}

M._util = {
  signs = vim.diagnostic.config().signs,
  active_wins = {},
}

function M.get_dir(dir)
  assert(dir == 'next' or dir == 'prev', 'invalid direction')

  local diag = dir == 'next' and vim.diagnostic.get_next()
    or vim.diagnostic.get_prev()
  if not diag then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end

  local pos = { diag.lnum, diag.col }
  local diagnostics = vim
    .iter(vim.diagnostic.get(0, { lnum = pos[1] }))
    :filter(function(d)
      return d.col == pos[2]
    end)
    :totable()

  if #diagnostics == 0 then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end

  M:_open({ type = 'dir', diag = diagnostics })
end

function M.get_line()
  local pos = vim.fn.getcurpos()
  local diag = vim.diagnostic.get(0, { lnum = pos[2] - 1 })

  if #diag == 0 then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
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

    tbl.diag[i].msg[1] = tbl.diag[i].msg[1]
  end

  for i = 1, #tbl.diag do
    for j = 2, #tbl.diag[i].msg do
      tbl.diag[i].msg[j] = (' '):rep(
        vim.fn.strdisplaywidth(self._util.signs.text[tbl.diag[i].sev])
      ) .. tbl.diag[i].msg[j]
    end
  end

  if raw.type == 'dir' then
    tbl.title.icon = {
      (' %s '):format(self._util.signs.text[tbl.diag[1].sev]),
      self._util.signs.numhl[tbl.diag[1].sev],
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
      (' %s '):format(self._util.signs.text[tbl.diag[1].sev]),
      self._util.signs.numhl[max_sev],
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
  local ns_id = vim.api.nvim_create_namespace('lsp-ui')
  local offset = -1

  for i = 1, #proc.diag do
    if #proc.diag[i].msg > 1 then
      for j = 1, #proc.diag[i].msg do
        vim.hl.range(
          bufnr,
          ns_id,
          self._util.signs.numhl[proc.diag[i].sev],
          { offset + i + j - 1, 0 },
          { offset + i + j - 1, -1 }
        )
      end
    end

    vim.hl.range(
      bufnr,
      ns_id,
      self._util.signs.numhl[proc.diag[i].sev],
      { offset + i + #proc.diag[i].msg - 1, 0 },
      {
        offset + i + #proc.diag[i].msg - 1,
        proc.diag[i].msg[#proc.diag[i].msg]:len(),
      }
    )
    vim.hl.range(bufnr, ns_id, 'NeutralFloat', {
      offset + (#proc.diag[i].msg > 1 and #proc.diag[i].msg - 1 or 0) + i,
      proc.diag[i].msg[#proc.diag[i].msg]:len(),
    }, {
      offset + (#proc.diag[i].msg > 1 and #proc.diag[i].msg - 1 or 0) + i,
      -1,
    })

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

  vim.iter(M._util.active_wins):each(L.win.close)
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

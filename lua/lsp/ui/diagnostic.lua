local L = require('lib')
local M = {}

local signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
  return vim.startswith(s.name, 'DiagnosticSign')
end)

local preprocess = function(raw)
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

    tbl[i].data[1] = signs[tbl[i].sev].text .. tbl[i].data[1]
  end

  for i = 1, #tbl do
    for j = 2, #tbl[i].data do
      tbl[i].data[j] = (' '):rep(vim.fn.strdisplaywidth(signs[tbl[i].sev].text))
        .. tbl[i].data[j]
    end
  end

  tbl.title.icon = raw.type == 'line'
      and { ' ' .. signs[3].text, signs[3].texthl }
    or {
      ' ' .. signs[tbl[1].sev].text,
      signs[tbl[1].sev].texthl,
    }
  tbl.title.loc = (
    raw.type == 'line' and tbl[1].ln or tbl[1].ln .. ':' .. tbl[1].vcol
  ) .. ' '

  return tbl
end

local format = function(proc)
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

local set_highlights = function(bufnr, proc)
  local offset = -1

  for i = 1, #proc do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      signs[proc[i].sev].texthl,
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

local open = function(raw)
  local proc = preprocess(raw)
  local content = format(proc)

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

  set_highlights(data.nbuf, proc)

  L.cmd.event(
    { 'BufLeave', 'CursorMoved', 'InsertEnter', 'WinNew' },
    data.obuf,
    function()
      L.win.close(data.nwin)
    end
  )
end

local try_diagnostic = function(type, pos)
  local diag = vim.diagnostic.get(0, { lnum = pos[1] })

  if type == 'dir' then
    diag = vim.fn.filter(diag, function(_, d)
      return d.col == pos[2]
    end)
  end

  if #diag == 0 then
    return vim.notify('No diagnostics found.', 2)
  end

  open({ type = type, diag = diag })
end

M.goto_next = function()
  try_diagnostic('dir', vim.diagnostic.get_next_pos() or { 0, 0 })
end
M.goto_prev = function()
  try_diagnostic('dir', vim.diagnostic.get_prev_pos() or { 0, 0 })
end
M.get_line = function()
  local pos = vim.fn.getcurpos()
  try_diagnostic('line', { pos[2] - 1, pos[3] - 1 })
end
return M

local L = require('utils.lib')
local M = {}

local preprocess = function(raw)
  local ret = { cword = raw.cword, peek = raw.peek }

  local res = raw.res
  if type(res[1]) == 'table' then
    res = res[1]
  end
  ret.uri = res.result.uri or res.result.targetUri

  local range = res.result.range or res.result.targetSelectionRange
  ret.start = { range.start.line + 1, range.start.character }
  ret._end = { range['end'].line + 1, range['end'].character }

  return ret
end

local set_highlights = function(bufnr, proc)
  local nsid = vim.api.nvim_create_namespace('LspUi')
  vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)

  vim.api.nvim_buf_add_highlight(
    bufnr,
    nsid,
    'Search',
    proc.start[1] - 1,
    proc.start[2],
    proc._end[2]
  )

  -- TODO: revise for multiline highlights
  if proc._end[1] > proc.start[1] then
    local current = proc.start[1]
    local last = proc._end[1]

    while current < last do
      vim.api.nvim_buf_add_highlight(bufnr, nsid, 'Search', current, 0, -1)
      current = current + 1
    end

    vim.api.nvim_buf_add_highlight(bufnr, nsid, 'Search', last, 0, proc._end[2])
  end

  L.key.nnmap('<C-l>', function()
    vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)
    L.key.unmap('n', '<C-l>', { buffer = true })
  end, { buffer = true, remap = false })
end

local register_float_actions = function(bufnr, winnr)
  local nsid = vim.api.nvim_create_namespace('LspUi')
  if winnr == nil then
    return
  end

  L.cmd.event('QuitPre', bufnr, function()
    if L.win.is_cur_valid(winnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)
    end
  end)

  L.cmd.event('WinLeave', bufnr, function()
    if L.win.is_cur_valid(winnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)
      vim.api.nvim_win_close(winnr, false)
    end
  end)
end

local open = function(raw)
  local proc = preprocess(raw)
  local bufnr = vim.uri_to_bufnr(proc.uri)

  if proc.peek or bufnr == vim.api.nvim_get_current_buf() then
    vim.api.nvim_win_set_buf(0, bufnr)
    set_highlights(bufnr, proc)
    vim.api.nvim_win_set_cursor(0, proc.start)
    return
  end

  local data = L.win.open_center(bufnr, true, true, {
    title = ' ' .. vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t') .. ' ',
    zindex = 1,
  })
  set_highlights(data.nbuf, proc)
  register_float_actions(data.nbuf, data.nwin)
  vim.api.nvim_win_set_cursor(data.nwin, proc.start)
  vim.cmd('norm! zt')
end

local try_definition = function(peek)
  local res = L.lsp.request(
    L.lsp.clients_by_cap('definition'),
    'textDocument/definition',
    vim.lsp.util.make_position_params(),
    0
  )
  if L.tbl.is_empty(res) then
    return
  end

  open({ cword = vim.fn.expand('<cword>'), res = res, peek = peek })
end

local try_type_defintion = function()
  local res = L.lsp.request(
    L.lsp.clients_by_cap('typeDefinition'),
    'textDocument/typeDefinition',
    vim.lsp.util.make_position_params(),
    0
  )
  if L.tbl.is_empty(res) then
    return
  end

  open({ cword = vim.fn.expand('<cword>'), res = res })
end

M.peek = function()
  try_definition(false)
end
M.open = function()
  try_definition(true)
end
M.type = function()
  try_type_defintion()
end
return M

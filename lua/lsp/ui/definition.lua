local L = require('lib')
local M = {}

local signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
  return vim.startswith(s.name, 'DiagnosticSign')
end)

local _def_highlight = function(bufnr, def)
  local nsid = vim.api.nvim_create_namespace('LspUi')
  vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)

  vim.api.nvim_buf_add_highlight(
    bufnr,
    nsid,
    'Search',
    def.start[1] - 1,
    def.start[2],
    def._end[2]
  )

  -- TODO: revise for multiline highlights
  if def._end[1] > def.start[1] then
    local current = def.start[1]
    local last = def._end[1]

    while current < last do
      vim.api.nvim_buf_add_highlight(bufnr, nsid, 'Search', current, 0, -1)
      current = current + 1
    end

    vim.api.nvim_buf_add_highlight(bufnr, nsid, 'Search', last, 0, def._end[2])
  end

  L.key.nnmap('<C-l>', function()
    vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)
    L.key.unmap('n', '<C-l>', { buffer = true })
  end, { buffer = true, remap = false })
end

local _def_actions = function(bufnr, winnr)
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

local _def_open = function(data, index)
  L.win.close(data.nwin)

  local proc = data.proc
  local bufnr = vim.uri_to_bufnr(proc.def[index].uri)

  if not proc.peek or bufnr == vim.api.nvim_get_current_buf() then
    vim.api.nvim_win_set_buf(data.owin, bufnr)
    _def_highlight(bufnr, proc.def[index])
    vim.api.nvim_win_set_cursor(data.owin, proc.def[index].start)
    return
  end

  ---@diagnostic disable-next-line: redefined-local
  local data = L.win.open_center(bufnr, true, {
    title = ' ' .. vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t') .. ' ',
    zindex = 1,
    style = '',
  })

  vim.bo[data.nbuf].bufhidden = 'hide'
  vim.bo[data.nbuf].modifiable = true

  _def_highlight(data.nbuf, proc.def[index])
  _def_actions(data.nbuf, data.nwin)
  vim.api.nvim_win_set_cursor(data.nwin, proc.def[index].start)
  vim.cmd('norm! zt')
end

--------------------------------------------------------------------------------

local preprocess = function(raw)
  local tbl = { cword = raw.cword, peek = raw.peek, def = {} }

  local workspace_folders = {}
  for i = 1, #raw.clients do
    local config = raw.clients[i]
    if config.workspace_folders then
      for j = 1, #config.workspace_folders do
        table.insert(workspace_folders, config.workspace_folders[j].uri)
      end
    else
      table.insert(workspace_folders, 'file://' .. config.root_dir)
    end
  end
  vim.fn.uniq(workspace_folders)

  local res = raw.res
  -- TODO: verify this works when lsp returns Location[] or LocationLink[]
  vim.fn.flatten(res, 1)
  local home = os.getenv('HOME')

  -- PERF: potentially significant runtime overhead for increased usability

  for i = 1, #res do
    local range = res[i].result.range or res[i].result.targetSelectionRange
    local def = {
      uri = res[i].result.uri or res[i].result.targetUri,
      file = (res[i].result.uri or res[i].result.targetUri)
        :gsub('^file://', '')
        :gsub('^' .. home, '~'),
      start = { range.start.line + 1, range.start.character },
      _end = { range['end'].line + 1, range['end'].character },
    }

    -- remove duplicate definitions on the same line
    for j = 1, #tbl.def do
      if def.start[1] ~= tbl.def[j].start[1] then
        goto continue
      end

      if
        def._end[1] < tbl.def[j]._end[1]
        or def._end[1] == tbl.def[j]._end[1]
          and def._end[2] < tbl.def[j]._end[2]
      then
        table.remove(tbl.def, j)
        break
      end

      goto skip
      ::continue::
    end

    table.insert(tbl.def, def)
    ::skip::
  end

  -- remove external definitions, if at least one local definition is present
  local workspace_only = false
  for i = 1, #tbl.def do
    for j = 1, #workspace_folders do
      if vim.startswith(tbl.def[i].uri, workspace_folders[j]) then
        workspace_only = true
        break
      end
    end
  end

  if not workspace_only then
    return tbl
  end

  local keep = {}
  for i = 1, #tbl.def do
    for j = 1, #workspace_folders do
      if vim.startswith(tbl.def[i].uri, workspace_folders[j]) then
        keep[i] = true
        goto continue
      end
    end
    ::continue::
  end

  for i = #tbl.def, 1, -1 do
    if not keep[i] then
      table.remove(tbl.def, i)
    end
  end

  return tbl
end

local format = function(proc)
  local tbl = {}

  for i = 1, #proc.def do
    table.insert(
      tbl,
      ('%s %s %s-%s'):format(
        i,
        proc.def[i].file,
        proc.def[i].start[1],
        proc.def[i]._end[1]
      )
    )
  end

  return tbl
end

local set_highlights = function(bufnr, proc)
  for i = 1, #proc.def do
    local len = string.len(i)

    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      signs[i % #signs ~= 0 and i % #signs or #signs].texthl,
      i - 1,
      0,
      len
    )
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      'NeutralFloat',
      i - 1,
      len + proc.def[i].file:len() + 2,
      -1
    )
  end
end

local register_float_actions = function(data)
  L.key.nnmap('<C-c>', function()
    L.win.close(data.nwin)
  end, { buffer = true })

  L.key.nnmap('<CR>', function()
    _def_open(data, vim.fn.line('.'))
  end, { buffer = true })

  for i = 1, #data.proc.def do
    L.key.nnmap(tostring(i), function()
      _def_open(data, i)
    end, { buffer = true })
  end

  for _, lhs in pairs({ 'v', 'V', '<C-v>' }) do
    L.key.nnmap(lhs, '', { buffer = true })
  end

  L.cmd.event({ 'WinLeave', 'QuitPre' }, data.nbuf, function()
    L.win.close(data.nwin)
  end)
end

local open = function(raw)
  local proc = preprocess(raw)
  local content = format(proc)

  if #proc.def == 1 then
    -- HACK: not clean, easiest way to integrate
    _def_open({ owin = 0, proc = proc }, 1)
    return
  end

  local data = L.win.open_cursor(content, true, {
    title = {
      { ' ' .. signs[3].text, signs[3].texthl },
      { 'Definition ', 'FloatTitle' },
    },
    zindex = 2,
  })
  data.proc = proc

  set_highlights(data.nbuf, data.proc)
  register_float_actions(data)
end

local try_definition = function(peek)
  local clients = L.lsp.clients_by_cap('definition')
  local res = L.lsp.request(
    clients,
    'textDocument/definition',
    vim.lsp.util.make_position_params(),
    0
  )
  if L.tbl.is_empty(res) then
    return
  end

  open({
    cword = vim.fn.expand('<cword>'),
    clients = clients,
    res = res,
    peek = peek,
  })
end

local try_type_defintion = function()
  local clients = L.lsp.clients_by_cap('typeDefinition')
  local res = L.lsp.request(
    clients,
    'textDocument/typeDefinition',
    vim.lsp.util.make_position_params(),
    0
  )
  if L.tbl.is_empty(res) then
    return
  end

  open({ cword = vim.fn.expand('<cword>'), clients = clients, res = res })
end

M.peek = function()
  try_definition(true)
end
M.open = function()
  try_definition(false)
end
M.type = function()
  try_type_defintion()
end
return M

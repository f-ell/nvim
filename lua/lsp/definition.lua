---@class lsp.ui.Definition : lsp.ui
local M = {}

M._util = {
  definition = {},
  signs = vim.diagnostic.config().signs,
}

function M.peek()
  local method = vim.lsp.protocol.Methods.textDocument_definition
  local clients = vim.lsp.get_clients({ bufnr = 0, method = method })
  local err, res = L.lsp.request(
    clients,
    method,
    vim.lsp.util.make_position_params(0, 'utf-8'),
    0
  )

  if err then
    L.lsp.notify_error(err)
    return
  end
  if L.tbl.is_empty(res) then
    vim.notify('No definition available', vim.log.levels.INFO)
    return
  end

  M:_open({
    cword = vim.fn.expand('<cword>'),
    clients = clients,
    res = res,
    peek = true,
  })
end

function M.open()
  local method = vim.lsp.protocol.Methods.textDocument_definition
  local clients = vim.lsp.get_clients({ bufnr = 0, method = method })
  local err, res = L.lsp.request(
    clients,
    method,
    vim.lsp.util.make_position_params(0, 'utf-8'),
    0
  )

  if err then
    L.lsp.notify_error(err)
    return
  end
  if L.tbl.isempty(res) then
    vim.notify('No definition available', vim.log.levels.INFO)
    return
  end

  M:_open({
    cword = vim.fn.expand('<cword>'),
    clients = clients,
    res = res,
    peek = false,
  })
end

function M.type()
  local method = vim.lsp.protocol.Methods.textDocument_typeDefinition
  local clients = vim.lsp.get_clients({ bufnr = 0, method = method })
  local err, res = L.lsp.request(
    clients,
    method,
    vim.lsp.util.make_position_params(0, 'utf-8'),
    0
  )

  if err then
    L.lsp.notify_error(err)
    return
  end
  if L.tbl.isempty(res) then
    vim.notify('No definition available', vim.log.levels.INFO)
    return
  end

  M:_open({
    cword = vim.fn.expand('<cword>'),
    clients = clients,
    res = res,
  })
end

function M._util.definition.set_highlights(bufnr, def)
  local nsid = vim.api.nvim_create_namespace('lsp-ui')
  vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)

  vim.hl.range(
    bufnr,
    nsid,
    'Search',
    { def.start[1] - 1, def.start[2] },
    { def._end[1], def._end[2] }
  )

  L.key.nnmap('<C-l>', function()
    vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)
    L.key.unmap('n', '<C-l>', { buffer = true })
  end, { buffer = true, remap = false })
end

function M._util.definition.register_float_actions(bufnr, winnr)
  local nsid = vim.api.nvim_create_namespace('lsp-ui')
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

function M._util.definition.open(data, index)
  L.win.close(data.nwin)

  local proc = data.proc
  local bufnr = vim.uri_to_bufnr(proc.def[index].uri)

  if not proc.peek or bufnr == vim.api.nvim_get_current_buf() then
    vim.api.nvim_win_set_buf(data.owin, bufnr)
    M._util.definition.set_highlights(bufnr, proc.def[index])
    vim.api.nvim_win_set_cursor(data.owin, proc.def[index].start)
    vim.cmd('filetype detect')
    vim.cmd('norm zz')
    return
  end

  data = L.win.open_center(bufnr, true, {
    title = ' ' .. vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t') .. ' ',
    zindex = 1,
    style = '',
  })
  vim.cmd('filetype detect')
  vim.cmd('norm zz')

  vim.bo[data.nbuf].bufhidden = 'hide'
  vim.bo[data.nbuf].modifiable = true

  M._util.definition.set_highlights(data.nbuf, proc.def[index])
  M._util.definition.register_float_actions(data.nbuf, data.nwin)
  vim.api.nvim_win_set_cursor(data.nwin, proc.def[index].start)
  vim.cmd('norm! zt')
end

function M:_preprocess(raw)
  local tbl = { cword = raw.cword, peek = raw.peek, def = {} }

  local workspace_folders = {}
  for i = 1, #raw.clients do
    local config = raw.clients[i]
    if config.workspace_folders then
      for j = 1, #config.workspace_folders do
        table.insert(workspace_folders, config.workspace_folders[j].uri)
      end
    elseif config.root_dir then
      table.insert(workspace_folders, 'file://' .. config.root_dir)
    end
  end
  vim.fn.uniq(workspace_folders)

  local res = raw.res
  -- TODO: verify this works when lsp returns Location[] or LocationLink[]
  vim.fn.flatten(res, 1)
  local home = os.getenv('HOME')

  -- potentially significant runtime overhead for increased usability
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

function M:_format(proc)
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

function M:_set_highlights(bufnr, proc)
  local ns_id = vim.api.nvim_create_namespace('lsp-ui')

  for i = 1, #proc.def do
    local len = string.len(i)

    vim.hl.range(
      bufnr,
      ns_id,
      self._util.signs.numhl[i % #self._util.signs.text ~= 0 and i % #self._util.signs.text or #self._util.signs.text],
      { i - 1, 0 },
      { i - 1, len }
    )
    vim.hl.range(
      bufnr,
      ns_id,
      'NeutralFloat',
      { i - 1, len + proc.def[i].file:len() + 2 },
      { i - 1, -1 }
    )
  end
end

function M:_register_float_actions(data)
  L.key.nnmap('<C-c>', function()
    L.win.close(data.nwin)
  end, { buffer = true })

  L.key.nnmap('<CR>', function()
    M._util.definition.open(data, vim.fn.line('.'))
  end, { buffer = true })

  for i = 1, #data.proc.def do
    L.key.nnmap(tostring(i), function()
      M._util.definition.open(data, i)
    end, { buffer = true })
  end

  for _, lhs in pairs({ 'v', 'V', '<C-v>' }) do
    L.key.nnmap(lhs, '', { buffer = true })
  end

  L.cmd.event({ 'WinLeave', 'QuitPre' }, data.nbuf, function()
    L.win.close(data.nwin)
  end)
end

function M:_open(raw)
  local proc = self:_preprocess(raw)
  local content = self:_format(proc)

  if #proc.def == 1 then
    self._util.definition.open({ owin = 0, proc = proc }, 1)
    return
  end

  local data = L.win.open_cursor(content, true, {
    title = {
      {
        (' %s '):format(self._util.signs.text[vim.diagnostic.severity.INFO]),
        self._util.signs.numhl[vim.diagnostic.severity.INFO],
      },
      { 'Definition ', 'FloatTitle' },
    },
    zindex = 2,
  })
  data.proc = proc

  self:_set_highlights(data.nbuf, proc)
  self:_register_float_actions(data)
end

return M

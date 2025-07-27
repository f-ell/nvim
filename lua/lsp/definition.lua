---@class (exact) lsp.ui.definition.Raw
---@field clients vim.lsp.Client[]
---@field cword string
---@field res LspResponse[]
---
---@class (exact) lsp.ui.definition.Def
---@field uri string
---@field file string
---@field start { [1]: number, [2]: number }
---@field _end { [1]: number, [2]: number }
---
---@class (exact) lsp.ui.definition.Proc
---@field cword string
---@field def lsp.ui.definition.Def[]

---@class lsp.ui.Definition : lsp.ui
local M = {
  _util = {
    definition = {},
    signs = vim.diagnostic.config().signs,
  },
}

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
  elseif L.tbl.isempty(res) then
    vim.notify('No definition available', vim.log.levels.INFO)
    return
  end

  M:_open({
    cword = vim.fn.expand('<cword>'),
    clients = clients,
    res = res,
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
  elseif L.tbl.isempty(res) then
    vim.notify('No definition available', vim.log.levels.INFO)
    return
  end

  M:_open({
    cword = vim.fn.expand('<cword>'),
    clients = clients,
    res = res,
  })
end

---@param bufnr number
---@param def lsp.ui.definition.Def
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

---@param data WinData
---@param index number
function M._util.definition.open(data, index)
  L.win.close(data.nwin)

  local proc = data.proc --[[@as lsp.ui.definition.Proc]]
  local bufnr = vim.uri_to_bufnr(proc.def[index].uri)

  vim.api.nvim_win_set_buf(data.owin, bufnr)
  M._util.definition.set_highlights(bufnr, proc.def[index])
  vim.api.nvim_win_set_cursor(data.owin, proc.def[index].start)
  vim.cmd('filetype detect')
  vim.cmd('norm zz')
end

---@param raw lsp.ui.definition.Raw
---@return lsp.ui.definition.Proc
function M:_preprocess(raw)
  ---@type lsp.ui.definition.Proc
  local tbl = { cword = raw.cword, def = {} }

  ---@type string[]
  local ws_folders = {}
  for _, c in pairs(raw.clients) do
    if c.workspace_folders then
      for _, w in pairs(c.workspace_folders) do
        table.insert(ws_folders, w.uri)
      end
    elseif c.root_dir then
      table.insert(ws_folders, 'file://' .. c.root_dir)
    end
  end
  vim.fn.uniq(ws_folders)

  local home = os.getenv('HOME')
  for _, res in pairs(raw.res) do
    local range = res.result.range or res.result.targetSelectionRange
    ---@type lsp.ui.definition.Def
    local def = {
      uri = res.result.uri or res.result.targetUri,
      file = (res.result.uri or res.result.targetUri)
        :gsub('^file://', '')
        :gsub('^' .. home, '~'),
      start = { range.start.line + 1, range.start.character },
      _end = { range['end'].line + 1, range['end'].character },
    }

    -- remove duplicate definitions on the same line
    for i, d in pairs(tbl.def) do
      if def.start[1] ~= d.start[1] then
        goto continue
      end

      if
        def._end[1] < d._end[1]
        or def._end[1] == d._end[1] and def._end[2] < d._end[2]
      then
        table.remove(tbl.def, i)
        break
      end

      goto skip
      ::continue::
    end

    table.insert(tbl.def, def)
    ::skip::
  end

  -- remove external definitions, if at least one local definition is present
  local ws_only = false
  for _, d in pairs(tbl.def) do
    for _, w in pairs(ws_folders) do
      if vim.startswith(d.uri, w) then
        ws_only = true
        break
      end
    end
  end

  if not ws_only then
    return tbl
  end

  ---@type boolean[]
  local keep = {}
  for i, d in pairs(tbl.def) do
    for _, w in pairs(ws_folders) do
      if vim.startswith(d.uri, w) then
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

---@param proc lsp.ui.definition.Proc
---@return string[]
function M:_format(proc)
  ---@type string[]
  local tbl = {}

  for i, d in pairs(proc.def) do
    table.insert(tbl, ('%s %s %s-%s'):format(i, d.file, d.start[1], d._end[1]))
  end

  return tbl
end

---@param bufnr number
---@param proc lsp.ui.definition.Proc
function M:_set_highlights(bufnr, proc)
  local ns_id = vim.api.nvim_create_namespace('lsp-ui')

  for i, d in pairs(proc.def) do
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
      { i - 1, len + d.file:len() + 2 },
      { i - 1, -1 }
    )
  end
end

---@param data WinData
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

---@param raw lsp.ui.definition.Raw
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

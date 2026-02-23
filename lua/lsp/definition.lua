---@class (exact) lsp.ui.def.Request
---@field clients vim.lsp.Client[]
---@field cword string
---@field responses lib.lsp.Response[]
---
---@class (exact) lsp.ui.def.Definition
---@field uri string
---@field file string
---@field start [number, number]
---@field end_ [number, number]

---@class lsp.ui.Definition
local M = {
  ---@package
  _util = {
    signs = vim.diagnostic.config().signs,
    ---@param item lsp.ui.def.Definition
    format = function(item, _, _)
      return {
        item.file,
        { ('%s-%s'):format(item.start[1], item.end_[1]), 'NonText' },
      }
    end,
  },
}

function M.open()
  local method = vim.lsp.protocol.Methods.textDocument_definition
  local clients = vim.lsp.get_clients({ bufnr = 0, method = method })
  local res, err = L.lsp:request(
    clients,
    method,
    vim.lsp.util.make_position_params(0, 'utf-8'),
    0
  )
  if err then
    L.lsp.notify_error(err)
    return
  end

  if table.isempty(res) then
    vim.notify('No definition available', vim.log.levels.INFO)
    return
  end

  M:_open({
    cword = vim.fn.expand('<cword>'),
    clients = clients,
    responses = res,
  })
end

function M.type()
  local method = vim.lsp.protocol.Methods.textDocument_typeDefinition
  local clients = vim.lsp.get_clients({ bufnr = 0, method = method })

  local res, err = L.lsp:request(
    clients,
    method,
    vim.lsp.util.make_position_params(0, 'utf-8'),
    0
  )
  if err then
    L.lsp.notify_error(err)
    return
  end

  if table.isempty(res) then
    vim.notify('No definition available', vim.log.levels.INFO)
    return
  end

  M:_open({
    cword = vim.fn.expand('<cword>'),
    clients = clients,
    responses = res,
  })
end

---@package
---@param req lsp.ui.def.Request
---@return lsp.ui.def.Definition[]
function M:_transform(req)
  ---@type lsp.ui.def.Definition[]
  local definitions = {}

  ---@type string[]
  local ws_folders = {}
  for _, c in pairs(req.clients) do
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

  ---@type (lsp.Location | lsp.LocationLink)[]
  local loc = vim
    .iter(req.responses)
    :map(
      ---@param r lib.lsp.Response
      function(r)
        return type(r.result[1]) == 'table' and r.result or { r.result }
      end
    )
    :flatten()
    :totable()

  for _, l in pairs(loc) do
    local range = l.range or l.targetSelectionRange

    ---@type lsp.ui.def.Definition
    local def = {
      uri = l.uri or l.targetUri,
      file = (l.uri or l.targetUri):gsub('^file://', ''):gsub('^' .. home, '~'),
      start = { range.start.line + 1, range.start.character },
      end_ = { range['end'].line + 1, range['end'].character },
    }

    -- Remove definitions that are fully contained in one another. The
    -- calculation is performed in a two-step process. `i` and `j` (see below)
    -- will never both be `nil` at the same time.
    local it = vim.iter(ipairs(definitions)):filter(
      ---@param d lsp.ui.def.Definition
      function(_, d)
        return d.start[1] == def.start[1]
      end
    )

    -- A previous definition is fully contained in `def`. Looking only for the
    -- first match works, since this is computed on every iteration.
    local i, _ = it:find(
      ---@param d lsp.ui.def.Definition
      function(_, d)
        return d.end_[1] < def.end_[1]
          or d.end_[1] == def.end_[1] and d.end_[2] < def.end_[2]
      end
    )
    if i ~= nil then
      table.remove(definitions, i)
    end

    -- `def` is fully contained in a previous definition.
    local j, _ = it:find(
      ---@param d lsp.ui.def.Definition
      function(_, d)
        return def.end_[1] < d.end_[1]
          or def.end_[1] == d.end_[1] and def.end_[2] < d.end_[2]
      end
    )
    if j == nil then
      table.insert(definitions, def)
    end
  end

  -- Remove definitions from external sources, such as dependencies, if at least
  -- one project-local definition exists.
  local ws_only = vim.iter(definitions):find(
    ---@param d lsp.ui.def.Definition
    function(d)
      for _, w in pairs(ws_folders) do
        if vim.startswith(d.uri, w) then
          return true
        end
      end
    end
  ) ~= nil

  if not ws_only then
    return definitions
  end

  return vim
    .iter(definitions)
    :filter(
      ---@param d lsp.ui.def.Definition
      function(d)
        for _, w in pairs(ws_folders) do
          if vim.startswith(d.uri, w) then
            return true
          end

          return false
        end
      end
    )
    :totable()
end

---@package
---@param bufnr number
---@param def lsp.ui.def.Definition
function M:_set_highlights(bufnr, def)
  local nsid = vim.api.nvim_create_namespace('lsp-ui')
  vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)

  vim.hl.range(
    bufnr,
    nsid,
    'Search',
    { def.start[1] - 1, def.start[2] },
    { def.end_[1] - 1, def.end_[2] }
  )

  L.key.nnmap('<C-l>', function()
    vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)
    L.key.unmap('n', '<C-l>', { buffer = true })
  end, { buffer = true, remap = false })
end

---@package
---@param d lsp.ui.def.Definition
function M:_goto(d)
  local bufnr = vim.uri_to_bufnr(d.uri)
  vim.api.nvim_win_set_buf(0, bufnr)
  self:_set_highlights(bufnr, d)

  vim.api.nvim_win_set_cursor(0, d.start)
  vim.cmd('filetype detect')
  vim.cmd('norm zz')
end

---@package
---@param req lsp.ui.def.Request
function M:_open(req)
  local definitions = self:_transform(req)

  if #definitions == 1 then
    self:_goto(definitions[1])
    return
  end

  local d = L.ui:pick(definitions, 'instant', self._util.format, {
    title = {
      {
        (' %s '):format(self._util.signs.text[vim.diagnostic.severity.INFO]),
        self._util.signs.numhl[vim.diagnostic.severity.INFO],
      },
      { 'Definition ', 'FloatTitle' },
    },
    zindex = 2,
  })[1]

  if d == nil then
    return
  end
  self:_goto(d)
end

return M

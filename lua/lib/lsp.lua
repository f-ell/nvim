---@class (exact) lsp.ResponseMessage
---@field id integer | string | nil @Request ID.
---@field error lsp.ResponseError?
---@field result lsp.LSPAny
---
---@class (exact) lib.lsp.Error
---@field id number @Client ID.
---@field name string @Client name.
---@field method string
---@field message string?
---
---@class (exact) lib.lsp.Response
---@field id number @Client ID.
---@field name string @Client name.
---@field result lsp.LSPAny

---@class lib.LSP
local LSP = {}

---Apply a workspace edit from an LSP reponse.
---
---@param response lib.lsp.Response
function LSP.apply_edit(response)
  local res = response.result --[[@as lsp.ApplyWorkspaceEditParams]]
  local edit = res.edit and res.edit or response.result --[[@as lsp.WorkspaceEdit]]

  vim.lsp.util.apply_workspace_edit(
    edit,
    vim.lsp.get_client_by_id(response.id).offset_encoding
  )

  --- WARN: out of spec, which servers rely on this?
  ---
  ---@cast res +{ action: fun()? }
  if res.action and type(res.action) == 'function' then
    vim.notify(
      'Applying out-of-spec workspace edit with field `action`.',
      vim.log.levels.WARN
    )
    res.action()
  end
end

---Format and print RequestError via `vim.notify`.
---
---@param errors lib.lsp.Error|lib.lsp.Error[]
---@param level vim.log.levels? @Defaults to `vim.log.levels.ERROR`.
function LSP.notify_error(errors, level)
  errors = type(errors[1]) == 'table' and errors or { errors }

  for _, e in pairs(errors) do
    vim.notify(
      ('%s: `%s` request failed%s'):format(
        e.name,
        e.method,
        e.message and ': ' .. e.message or ''
      ),
      level or vim.log.levels.ERROR
    )
  end
end

---@package
---Send request and handle returned result for the given client.
---
---@param client vim.lsp.Client
---@param params table
---@param bufnr number @Buffer to use for requests.
---@param timeout number @Passed as `timeout` parameter to `wait`.
---@return lib.lsp.Error?, lib.lsp.Response[]?
function LSP:_do_request(client, method, params, bufnr, timeout)
  ---@type lsp.ResponseMessage
  local msg
  ---@type lib.lsp.Error, lib.lsp.Response[]
  local error, responses = nil, {}

  ---Handler to use for the request to the server. Wraps any handlers already
  ---defined on the client and uses them to process the result.
  ---
  ---@type lsp.Handler
  local function handler(err, result, ctx, config)
    local h = client.handlers[method]

    if not h then
      msg = { error = err, result = result } --[[@as lsp.ResponseMessage]]
      return
    end

    local ok, res = pcall(h, err, result, ctx, config or {})
    if ok then
      msg = { error = res.err, result = res.result } --[[@as lsp.ResponseMessage]]
      return
    end

    -- FIX: do we need this or can we simply fail here? Poor implementation
    -- regardless - sync-request should not be nested in async handler.
    --
    -- Try a direct request to the server, if the default handler failed.
    local rs_res = client:request_sync(method, params, 800, bufnr)
    if rs_res then
      msg = { error = rs_res.err, result = rs_res.result }
      return
    end

    msg = { error = err, result = result } --[[@as lsp.ResponseMessage]]
  end

  -- Send request and await result.
  local status, req_id = client:request(method, params, handler, bufnr)
  if status == false then
    return {
      id = client.id,
      name = client.name,
      method = method,
      message = 'client not available',
    }, --[[@as lib.lsp.Error]]
      nil
  end

  local wait = vim.fn.wait(timeout, function()
    return client.requests[req_id] == nil
  end, 50)

  -- Handle non-graceful request termination.
  if wait == -1 then
    error = {
      id = client.id,
      name = client.name,
      method = method,
      message = 'timeout',
    }
  elseif wait == -2 then
    error = {
      id = client.id,
      name = client.name,
      method = method,
      message = 'interrupt',
    }
  elseif wait == -3 then
    error = {
      id = client.id,
      name = client.name,
      method = method,
      message = 'internal error',
    }
  end

  if error then
    return error, nil
  end

  -- Graceful request termination, handling internal errors and request
  -- post-processing.
  if msg.error then
    -- stylua: ignore
    return {
      id = client.id,
      name = client.name,
      method = method,
      message = msg.error.message,
    } --[[@as lib.lsp.Error]],
      nil
  end

  local res = type(msg.result[1]) == 'table' and msg.result or { msg.result } --[[ @as lsp.LSPAny[] ]]
  responses = vim
    .iter(res)
    :map(
      ---@param r lsp.LSPAny
      function(r)
        return { id = client.id, name = client.name, result = r } --[[@as lib.lsp.Response]]
      end
    )
    :totable()

  return error, responses
end

---Aggregate responses for the given method from all clients. Ignores global
---handlers (i.e. `vim.lsp.handlers`), but respects client-local handlers.
---Handlers on clients are expected to return `[err, result]`-tuples.
---
---@param clients vim.lsp.Client|vim.lsp.Client[]
---@param method string
---@param params table
---@param bufnr number? @Buffer to use for requests, defaults to '0'.
---@param timeout number? @Passed as `timeout` parameter to `wait`, defaults to '2000'.
---@return lib.lsp.Error[]?, lib.lsp.Response[]
function LSP:request(clients, method, params, bufnr, timeout)
  if
    type(clients) == 'table'
    and not (type(clients[1]) == 'table' or table.isempty(clients))
  then
    clients = { clients }
  end

  bufnr = bufnr or 0
  timeout = timeout or 2000
  ---@type lib.lsp.Error[], lib.lsp.Response[][]
  local errors, responses = {}, {}

  for _, c in pairs(clients) do
    local e, r = self:_do_request(c, method, params, bufnr, timeout)
    table.insert(errors, e)
    table.insert(responses, r)
  end
  responses = vim.fn.flatten(responses) --[[ @as lib.lsp.Response[] ]]

  return #errors > 0 and errors or nil, responses
end

return LSP

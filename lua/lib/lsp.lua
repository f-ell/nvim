---@class (exact) lsp.Response
---@field err lsp.ResponseError?
---@field result lsp.LSPAny
---
---@class (exact) lib.lsp.Error
---@field id number @Client ID.
---@field name string @Client name.
---@field method vim.lsp.protocol.Method
---@field message string?
---
---@class (exact) lib.lsp.Response
---@field id number @Client ID.
---@field name string @Client name.
---@field method vim.lsp.protocol.Method
---@field result lsp.LSPAny

---@class lib.LSP
local LSP = {}

---Apply a workspace edit from an LSP reponse.
---
---@param response lib.lsp.Response
function LSP.apply_edit(response)
  local r = response.result --[[@as lsp.ApplyWorkspaceEditParams]]
  local edit = r.edit and r.edit or response.result --[[@as lsp.WorkspaceEdit]]

  vim.lsp.util.apply_workspace_edit(
    edit,
    vim.lsp.get_client_by_id(response.id).offset_encoding
  )

  --- WARN: out of spec, which servers rely on this?
  ---
  ---@cast r +{ action: fun()? }
  if r.action and type(r.action) == 'function' then
    vim.notify(
      ('Calling out-of-spec action for `%s`'):format(response.name),
      vim.log.levels.WARN
    )
    r.action()
  end
end

---Format and print RequestError via `vim.notify`.
---
---@param errors lib.lsp.Error|lib.lsp.Error[]
---@param level vim.log.levels? @Defaults to `vim.log.levels.ERROR`.
function LSP.notify_error(errors, level)
  if type(errors[1]) ~= 'table' then
    errors = { errors }
  end

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
---@param method vim.lsp.protocol.Method
---@param params table
---@param bufnr number @Buffer to use for requests.
---@param timeout number @Passed as `timeout` parameter to `wait`.
---@return lib.lsp.Response, lib.lsp.Error?
function LSP:_do_request(client, method, params, bufnr, timeout)
  ---@type lsp.Response
  local res
  ---Wraps the client's handler for this method to populate `res`.
  ---
  ---@type lsp.Handler
  local function handler(e, r, ctx, cfg)
    -- Grab and use the client's handler for this method if one exists.
    local h = client.handlers[method]
    if not h then
      res = { err = e, result = r }
      return
    end

    local ok, pres = pcall(h, e, r, ctx, cfg or {})
    if ok then
      -- Servers may return an empty- / nil-response when no work should be done.
      res = table.isempty(pres) and {}
        or { err = pres.err, result = pres.result }
      return
    end

    -- FIX: do we need this or can we simply fail here? Poor implementation
    -- regardless - sync-request should not be nested in async handler.
    --
    -- Try a direct request to the server, if the default handler failed.
    local sync_res = client:request_sync(method, params, timeout, bufnr)
    if sync_res then
      res = sync_res
      return
    end

    res = { error = e, result = r }
  end

  local ok, id = client:request(method, params, handler, bufnr)
  if not ok then
    return {}, {
      id = client.id,
      name = client.name,
      method = method,
      message = 'client shut down',
    } --[[@as lib.lsp.Error]]
  end

  -- Poll request completion.
  local wait = vim.fn.wait(timeout, function()
    return client.requests[id] == nil
  end, 50)

  -- Handle non-graceful request termination.
  local wait_err
  if wait == -1 then
    wait_err = {
      id = client.id,
      name = client.name,
      method = method,
      message = 'timeout',
    }
  elseif wait == -2 then
    wait_err = {
      id = client.id,
      name = client.name,
      method = method,
      message = 'interrupt',
    }
  elseif wait == -3 then
    wait_err = {
      id = client.id,
      name = client.name,
      method = method,
      message = 'internal error',
    }
  end

  if wait_err then
    return {}, wait_err
  end

  -- Graceful request termination, handling internal errors and request
  -- post-processing.
  if res.err then
    return {}, {
      id = client.id,
      name = client.name,
      method = method,
      message = res.err.message,
    } --[[@as lib.lsp.Error]]
  end

  return {
    id = client.id,
    name = client.name,
    result = res.result,
  }, --[[@as lib.lsp.Response]]
    nil
end

---Aggregate responses for the given method from all clients. Ignores global
---handlers (i.e. `vim.lsp.handlers`), but respects client-local handlers.
---Handlers on clients are expected to return `[result, err]`-tuples.
---
---@param clients vim.lsp.Client|vim.lsp.Client[]
---@param method vim.lsp.protocol.Method
---@param params table
---@param bufnr number? @Buffer to use for requests, defaults to '0'.
---@param timeout number? @Passed as `timeout` parameter to `wait`, defaults to '2000'.
---@return lib.lsp.Response[], lib.lsp.Error[]?
function LSP:request(clients, method, params, bufnr, timeout)
  if table.isempty(clients) then
    return {}, nil
  end

  if type(clients[1]) ~= 'table' then
    clients = { clients }
  end

  bufnr = bufnr or 0
  timeout = timeout or 2000

  ---@type lib.lsp.Response[], lib.lsp.Error[]
  local res, err = {}, {}

  -- PERF: these could be parallelized.
  for _, c in pairs(clients) do
    local r, e = self:_do_request(c, method, params, bufnr, timeout)

    -- Requests return either a response, or an error. Ignore requests that
    -- don't return a value in time.
    if e then
      table.insert(err, e)
    elseif
      r
      and (
        type(r.result) == 'table'
          and not table.isempty(r.result --[[@as table]])
        or r.result ~= nil
      )
    then
      table.insert(res, r)
    end
  end

  return res, #err > 0 and err or nil
end

return LSP

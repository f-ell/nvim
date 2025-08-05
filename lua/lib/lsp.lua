---@class lib.LSP
local LSP = {}

---Apply a workspace edit from an LSP reponse.
---
---@param response LspResponse
function LSP.apply_edit(response)
  local edit = response.result.edit and response.result.edit or response.result

  vim.lsp.util.apply_workspace_edit(
    edit,
    vim.lsp.get_client_by_id(response.id).offset_encoding
  )

  if response.result.action and type(response.result.action) == 'function' then
    response.result.action()
  end
end

---Format and print RequestError via `vim.notify`.
---
---@param errors RequestError|RequestError[]
---@param level vim.log.levels? @Defaults to `vim.log.levels.ERROR`.
function LSP.notify_error(errors, level)
  errors = type(errors[1]) == 'table' and errors or { errors }

  for i = 1, #errors do
    vim.notify(
      ('%s: `%s` request failed%s'):format(
        errors[i].name,
        errors[i].method,
        errors[i].message and ': ' .. errors[i].message or ''
      ),
      level or vim.log.levels.ERROR
    )
  end
end

---Aggregate responses for the given method from all clients.
---Ignores global handlers (i.e. `vim.lsp.handlers`), but respects client-local
---handlers. Handlers on clients are expected to return `[err, result]`-tuples.
---
---@param clients vim.lsp.Client|vim.lsp.Client[]
---@param method string
---@param params table
---@param bufnr number? @Buffer to use for requests, defaults to '0'.
---@param timeout number? @Passed as `timeout` parameter to `wait`, defaults to '2000'.
---@return RequestError[]?,LspResponse[]
function LSP.request(clients, method, params, bufnr, timeout)
  if
    type(clients) == 'table'
    and not (type(clients[1]) == 'table' or table.isempty(clients))
  then
    clients = { clients }
  end

  bufnr = bufnr or 0
  local errors, responses = {}, {}

  ---@diagnostic disable-next-line: redefined-local
  local function add_err(name, method, message)
    table.insert(errors, { name = name, method = method, message = message })
  end
  local function add_res(id, name, result)
    table.insert(responses, { id = id, name = name, result = result })
  end

  for i = 1, #clients do
    local handler = function(err, result, ctx, config)
      local res, msg
      local _h = clients[i].handlers[method]

      if _h then
        local ok
        ok, res = pcall(_h, err, result, ctx, config or {})

        -- FIX: poor implementation, should not be nested in async-request
        if not ok then
          res = clients[i]:request_sync(method, params, 800, bufnr)
        end
      else
        res = { err = err, result = result }
      end

      if not res then
        add_err(clients[i].name, method, msg)
        goto continue
      end
      if res.err then
        add_err(clients[i].name, method, res.err.message)
        goto continue
      end
      if table.isempty(res.result) then
        goto continue
      end

      res.result = type(res.result[1]) == 'table' and res.result
        or { res.result }
      for j = 1, #res.result do
        add_res(clients[i].id, clients[i].name, res.result[j])
      end
      ::continue::
    end

    local status, request = clients[i]:request(method, params, handler, bufnr)
    if status == false then
      return {
        name = clients[i].name,
        method = method,
        message = 'client not available',
      }, {}
    end

    local wait = vim.fn.wait(timeout or 2000, function()
      return clients[i].requests[request] == nil
    end, 50)

    if wait == -1 then
      return {
        name = clients[i].name,
        method = method,
        message = 'timeout',
      }, {}
    elseif wait == -2 then
      return {
        name = clients[i].name,
        method = method,
        message = 'interrupt',
      }, {}
    elseif wait == -3 then
      return {
        name = clients[i].name,
        method = method,
        message = 'internal error',
      }, {}
    end
  end

  return #errors > 0 and errors or nil, responses
end

return LSP

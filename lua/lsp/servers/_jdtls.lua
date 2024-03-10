local M = {}

-- TODO: support field picking
local function generateToStringPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)

  local err, res =
    L.lsp.request(client, 'java/checkToStringStatus', ctx.params, ctx.bufnr)

  if err then
    L.lsp.notify_error(err[1], vim.log.levels.ERROR)
    return
  end

  res = res[1]
  if res.result.exists then
    vim.notify(
      ('`toString()` already exists in `%s`'):format(res.result.type),
      vim.log.levels.INFO
    )
    return
  end

  _, res = L.lsp.request(
    client,
    'java/generateToString',
    { context = ctx.params, fields = res.result.fields },
    ctx.bufnr
  )
  L.lsp.apply_edit(res[1])
end

-- TODO: support method picking (default: select all not from java.lang.Object)
local function overrideMethodsPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local err, res

  err, res =
    L.lsp.request(client, 'java/listOverridableMethods', ctx.params, ctx.bufnr)

  if err then
    L.lsp.notify_error(err)
    return
  end

  res = res[1]
  if not res or L.tbl.is_empty(res.result.methods) then
    vim.notify('No overridable methods found', vim.log.levels.INFO)
    return
  end

  -- local fmt = function(method)
  --   return ('%s(%s) via %s'):format(
  --     method.name,
  --     table.concat(method.parameters, ', '),
  --     method.declaringClass
  --   )
  -- end

  err, res = L.lsp.request(
    client,
    'java/addOverridableMethods',
    { context = ctx.params, overridableMethods = res.result.methods },
    ctx.bufnr
  )

  if err then
    L.lsp.notify_error(err)
    return
  end

  L.lsp.apply_edit(res[1])
end

M.commands = {
  ['java.action.generateToStringPrompt'] = generateToStringPrompt,
  ['java.action.overrideMethodsPrompt'] = overrideMethodsPrompt,
}

return M

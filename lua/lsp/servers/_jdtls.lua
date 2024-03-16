local M = {}

M._util = {
  signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
    return vim.startswith(s.name, 'DiagnosticSign')
  end),
}

local function generateToStringPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)

  local err, res =
    L.lsp.request(client, 'java/checkToStringStatus', ctx.params, ctx.bufnr)

  if err then
    L.lsp.notify_error(err)
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

  local function format(field, selected)
    return ('%s%s %s'):format(selected and '* ' or '', field.type, field.name)
  end

  local function callback(fields)
    err, res = L.lsp.request(
      client,
      'java/generateToString',
      { context = ctx.params, fields = fields },
      ctx.bufnr
    )

    if err then
      L.lsp.notify_error(err)
      return
    end

    L.lsp.apply_edit(res[1])
  end

  local preselect = {}
  for i = 1, #res.result.fields do
    table.insert(preselect, i)
  end

  L.ui.pick(res.result.fields, preselect, format, callback, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { 'toString ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })
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

  local function format(method, selected)
    return ('%s%s(%s) via %s'):format(
      selected and '* ' or '',
      method.name,
      table.concat(method.parameters, ', '),
      method.declaringClass
    )
  end

  local function callback(methods)
    err, res = L.lsp.request(
      client,
      'java/addOverridableMethods',
      { context = ctx.params, overridableMethods = methods },
      ctx.bufnr
    )

    if err then
      L.lsp.notify_error(err)
      return
    end

    L.lsp.apply_edit(res[1])
  end

  local preselect = {}
  for i = 1, #res.result.methods do
    if res.result.methods[i].declaringClass == 'java.lang.Object' then
      table.insert(preselect, i)
    end
  end

  L.ui.pick(res.result.methods, preselect, format, callback, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { '@Override ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })
end

M.commands = {
  ['java.action.generateToStringPrompt'] = generateToStringPrompt,
  ['java.action.overrideMethodsPrompt'] = overrideMethodsPrompt,
}

return M

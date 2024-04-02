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
      ('`toString` already exists in `%s`'):format(res.result.type),
      vim.log.levels.INFO
    )
    return
  end

  local function format(item, selected)
    return ('%s%s %s'):format(selected and '* ' or '', item.type, item.name)
  end

  local preselect = {}
  for i = 1, #res.result.fields do
    table.insert(preselect, i)
  end

  local items = L.ui.pick(res.result.fields, preselect, format, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { 'toString ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  err, res = L.lsp.request(
    client,
    'java/generateToString',
    { context = ctx.params, fields = items },
    ctx.bufnr
  )

  if err then
    L.lsp.notify_error(err)
    return
  end

  L.lsp.apply_edit(res[1])
end

local function hashCodeEqualsPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)

  local err, res = L.lsp.request(
    client,
    'java/checkHashCodeEqualsStatus',
    ctx.params,
    ctx.bufnr
  )

  if err then
    L.lsp.notify_error(err)
    return
  end

  res = res[1]
  if not res or L.tbl.is_empty(res.result.fields) then
    vim.notify(
      ('`hashCodeEquals` not applicable for type `%s`'):format(res.result.type),
      vim.log.levels.INFO
    )
    return
  end

  if #res.result.existingMethods == 2 then
    vim.notify(
      ('`hashCode` and `equals` already exist in `%s`'):format(res.result.type),
      vim.log.levels.INFO
    )
    return
  end
  local exists = res.result.existingMethods[1]

  local function format(item, selected)
    return ('%s%s %s'):format(selected and '* ' or '', item.type, item.name)
  end

  local preselect = {}
  for i = 1, #res.result.fields do
    table.insert(preselect, i)
  end

  local items = L.ui.pick(res.result.fields, preselect, format, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { 'hashCodeEquals ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  err, res = L.lsp.request(
    client,
    'java/generateHashCodeEquals',
    { context = ctx.params, fields = items },
    ctx.bufnr
  )

  if err then
    L.lsp.notify_error(err)
    return
  end

  if exists then
    local uri = vim.fn.keys(res[1].result.changes)

    for i = 1, #uri do
      for j = 1, #res[1].result.changes[uri[i]] do
        local c = res[1].result.changes[uri[i]][j]
        c.newText = c.newText:gsub(
          ('@Override\npublic %%l+ %s.- {.-}'):format(exists),
          ''
        )
      end
    end
  end

  L.lsp.apply_edit(res[1])
end

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

  local function format(item, selected)
    return ('%s%s(%s) via %s'):format(
      selected and '* ' or '',
      item.name,
      table.concat(item.parameters, ', '),
      item.declaringClass
    )
  end

  local preselect = {}
  for i = 1, #res.result.methods do
    if res.result.methods[i].declaringClass == 'java.lang.Object' then
      table.insert(preselect, i)
    end
  end

  local items = L.ui.pick(res.result.methods, preselect, format, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { '@Override ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  err, res = L.lsp.request(
    client,
    'java/addOverridableMethods',
    { context = ctx.params, overridableMethods = items },
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
  ['java.action.hashCodeEqualsPrompt'] = hashCodeEqualsPrompt,
  ['java.action.overrideMethodsPrompt'] = overrideMethodsPrompt,
}

return M

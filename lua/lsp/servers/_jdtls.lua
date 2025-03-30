local M = {}

M._util = {
  signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
    return vim.startswith(s.name, 'DiagnosticSign')
  end),
}

local function generateConstructorsPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local err, res

  err, res = L.lsp.request(
    { client },
    'java/checkConstructorsStatus',
    ctx.params,
    ctx.bufnr
  )

  if err then
    L.lsp.notify_error(err)
    return
  end

  res = res[1]
  if
    not res
    or not res.result.constructors
    or #res.result.constructors == 0
  then
    return
  end

  local function format(item, selected)
    return ('%s%s(%s)'):format(
      selected and '* ' or '',
      item.name,
      table.concat(item.parameters, ',')
    )
  end

  if L.tbl.is_empty(res.result.constructors) then
    vim.notify('No constructors found', vim.log.levels.INFO)
    return
  end

  local constructors = L.ui.pick(res.result.constructors, true, format, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { 'generateConstructors:constructors ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  if L.tbl.is_empty(constructors) then
    return
  end

  local fields = res.result.fields
  if fields then
    ---@diagnostic disable-next-line: redefined-local
    local function format(item, selected)
      return ('%s%s %s'):format(selected and '* ' or '', item.type, item.name)
    end

    fields = L.ui.pick(fields, { -1 }, format, {
      title = {
        { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
        { 'generateConstructors:fields ', 'FloatTitle' },
        { '<ESC> to confirm ', 'NeutralFloat' },
      },
    })
  end

  local params =
    { context = ctx.params, constructors = constructors, fields = fields }
  err, res =
    L.lsp.request({ client }, 'java/generateConstructors', params, ctx.bufnr)

  if err then
    L.lsp.notify_error(err)
    return
  end

  L.lsp.apply_edit(res[1])
end

local function generateDelegateMethodsPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local err, res

  err, res = L.lsp.request(
    { client },
    'java/checkDelegateMethodsStatus',
    ctx.params,
    ctx.bufnr
  )

  if err then
    L.lsp.notify_error(err)
    return
  end

  res = res[1]
  if not res or L.tbl.is_empty(res.result.delegateFields) then
    vim.notify('Delegate methods already exist', vim.log.levels.INFO)
    return
  end

  local function format(item, selected)
    return ('%s%s %s'):format(
      selected and '* ' or '',
      item.field.type,
      item.field.name
    )
  end

  local field = #res.result.delegateFields == 1 and res.result.delegateFields[1]
    or L.ui.pick(res.result.delegateFields, false, format, {
      title = {
        { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
        { 'generateDelegateMethods:target ', 'FloatTitle' },
        { '<ESC> to confirm ', 'NeutralFloat' },
      },
    })[1]

  if not field then
    return
  end
  if #field.delegateMethods == 0 then
    vim.notify('Delegate methods already exist', vim.log.levels.INFO)
    return
  end

  ---@diagnostic disable-next-line: redefined-local
  local function format(item, selected)
    return ('%s%s(%s)'):format(
      selected and '* ' or '',
      item.name,
      table.concat(item.parameters, ',')
    )
  end

  local methods = L.ui.pick(field.delegateMethods, true, format, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { 'generateDelegateMethods:method ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  if L.tbl.is_empty(methods) then
    return
  end

  local params = {
    context = ctx.params,
    delegateEntries = vim.tbl_map(function(method)
      return {
        field = field.field,
        delegateMethod = method,
      }
    end, methods),
  }

  err, res =
    L.lsp.request({ client }, 'java/generateDelegateMethods', params, ctx.bufnr)

  if err then
    L.lsp.notify_error(err)
    return
  end

  L.lsp.apply_edit(res[1])
end

local function generateToStringPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)

  local err, res =
    L.lsp.request({ client }, 'java/checkToStringStatus', ctx.params, ctx.bufnr)

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

  local items = L.ui.pick(res.result.fields, { -1 }, format, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { 'toString ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  err, res = L.lsp.request(
    { client },
    'java/generateToString',
    ---@diagnostic disable-next-line
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
    { client },
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

  local items = L.ui.pick(res.result.fields, { -1 }, format, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { 'hashCodeEquals ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  err, res = L.lsp.request(
    { client },
    'java/generateHashCodeEquals',
    ---@diagnostic disable-next-line
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

local function organizeImportsChooseImports(result)
  local ns_id = vim.api.nvim_create_namespace('jdtls')
  local uri, missing = result[1], result[2]

  local chosen = {}
  for i = 1, #missing do
    local r = missing[i].range

    vim.api.nvim_win_set_buf(0, vim.uri_to_bufnr(uri))
    vim.api.nvim_win_set_cursor(0, { r.start.line + 1, r.start.character })
    vim.api.nvim_command('normal zz')
    vim.hl.range(
      0,
      ns_id,
      'Search',
      { r.start.line, r.start.character },
      { r['end'].line, r['end'].character }
    )
    vim.api.nvim_command('redraw')

    local candidates = missing[i].candidates

    if #candidates == 1 then
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      table.insert(chosen, candidates[1])
    else
      local fqn = candidates[1].fullyQualifiedName
      local type = fqn:sub(L.str.last_index(fqn, '%.') + 2)

      local function format(item, selected)
        return ('%s%s'):format(selected and '* ' or '', item.fullyQualifiedName)
      end

      local items = L.ui.pick(candidates, false, format, {
        title = {
          { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
          { 'chooseImports:' .. type .. ' ', 'FloatTitle' },
          { '<ESC> to confirm ', 'NeutralFloat' },
        },
      })

      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      chosen = vim.fn.extend(chosen, items)
    end
  end

  return chosen
end

local function overrideMethodsPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local err, res

  err, res = L.lsp.request(
    { client },
    'java/listOverridableMethods',
    ctx.params,
    ctx.bufnr
  )

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

  local multi = {}
  for i = 1, #res.result.methods do
    if res.result.methods[i].declaringClass == 'java.lang.Object' then
      table.insert(multi, i)
    end
  end

  local items = L.ui.pick(res.result.methods, multi, format, {
    title = {
      { ' ' .. M._util.signs[3].text, M._util.signs[3].texthl },
      { '@Override ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  err, res = L.lsp.request(
    { client },
    'java/addOverridableMethods',
    ---@diagnostic disable-next-line
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
  ['java.action.generateConstructorsPrompt'] = generateConstructorsPrompt,
  ['java.action.generateDelegateMethodsPrompt'] = generateDelegateMethodsPrompt,
  ['java.action.generateToStringPrompt'] = generateToStringPrompt,
  ['java.action.hashCodeEqualsPrompt'] = hashCodeEqualsPrompt,
  ['java.action.organizeImports.chooseImports'] = organizeImportsChooseImports,
  ['java.action.overrideMethodsPrompt'] = overrideMethodsPrompt,
}

if not vim.lsp.handlers['workspace/executeClientCommand'] then
  vim.lsp.handlers['workspace/executeClientCommand'] = function(_, params, ctx)
    local cmd = (vim.lsp.get_client_by_id(ctx.client_id) or {}).commands or {}
    local _cmd = vim.tbl_extend('force', vim.lsp.commands, M.commands)
    local fn = cmd[params.command] or _cmd[params.command]

    if not fn then
      return vim.lsp.rpc_response_error(
        vim.lsp.protocol.ErrorCodes.MethodNotFound,
        ('`%s` not supported by client'):format(params.command)
      )
    end

    local ok, res = pcall(fn, params.arguments, ctx)
    if ok then
      return res
    else
      return vim.lsp.rpc_response_error(
        vim.lsp.protocol.ErrorCodes.InternalError,
        res
      )
    end
  end
end

return M

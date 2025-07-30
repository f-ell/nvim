-- capabilities and extendedClientCapabilities via https://github.com/mfussenegger/nvim-jdtls

local signs = vim.diagnostic.config().signs
---@cast signs -nil

local commands = {}

commands['java.action.generateConstructorsPrompt'] = function(_, ctx)
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
    return {
      { selected and '*' or '', 'NonText' },
      ('%s(%s)'):format(item.name, table.concat(item.parameters, ',')),
    }
  end

  if L.tbl.isempty(res.result.constructors) then
    vim.notify('No constructors found', vim.log.levels.INFO)
    return
  end

  local constructors = L.ui.pick(res.result.constructors, 'yes', format, {
    title = {
      {
        (' %s '):format(signs.text[vim.diagnostic.severity.INFO]),
        signs.numhl[vim.diagnostic.severity.INFO],
      },
      { 'generateConstructors:constructors ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  if L.tbl.isempty(constructors) then
    return
  end

  local fields = res.result.fields
  if fields then
    ---@diagnostic disable-next-line: redefined-local
    local function format(item, selected)
      return {
        { selected and '*' or '', 'NonText' },
        ('%s %s'):format(item.type, item.name),
      }
    end

    fields = L.ui.pick(fields, { -1 }, format, {
      title = {
        {
          (' %s '):format(signs.text[vim.diagnostic.severity.INFO]),
          signs.numhl[vim.diagnostic.severity.INFO],
        },
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

commands['java.action.generateDelegateMethodsPrompt'] = function(_, ctx)
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
  if not res or L.tbl.isempty(res.result.delegateFields) then
    vim.notify('Delegate methods already exist', vim.log.levels.INFO)
    return
  end

  local function format(item, selected)
    return {
      { selected and '*' or '', 'NonText' },
      ('%s %s'):format(item.field.type, item.field.name),
    }
  end

  local field = #res.result.delegateFields == 1 and res.result.delegateFields[1]
    or L.ui.pick(res.result.delegateFields, 'instant', format, {
      title = {
        {
          (' %s '):format(signs.text[vim.diagnostic.severity.INFO]),
          signs.numhl[vim.diagnostic.severity.INFO],
        },
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
    return {
      { selected and '*' or '', 'NonText' },
      ('%s(%s)'):format(item.name, table.concat(item.parameters, ',')),
    }
  end

  local methods = L.ui.pick(field.delegateMethods, 'yes', format, {
    title = {
      {
        (' %s '):format(signs.text[vim.diagnostic.severity.INFO]),
        signs.numhl[vim.diagnostic.severity.INFO],
      },
      { 'generateDelegateMethods:method ', 'FloatTitle' },
      { '<ESC> to confirm ', 'NeutralFloat' },
    },
  })

  if L.tbl.isempty(methods) then
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

commands['java.action.generateToStringPrompt'] = function(_, ctx)
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
    return {
      { selected and '*' or '', 'NonText' },
      ('%s %s'):format(item.type, item.name),
    }
  end

  local items = L.ui.pick(res.result.fields, { -1 }, format, {
    title = {
      {
        (' %s '):format(signs.text[vim.diagnostic.severity.INFO]),
        signs.numhl[vim.diagnostic.severity.INFO],
      },
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

commands['java.action.hashCodeEqualsPrompt'] = function(_, ctx)
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
  if not res or L.tbl.isempty(res.result.fields) then
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
    return {
      { selected and '*' or '', 'NonText' },
      ('%s %s'):format(item.type, item.name),
    }
  end

  local items = L.ui.pick(res.result.fields, { -1 }, format, {
    title = {
      {
        (' %s '):format(signs.text[vim.diagnostic.severity.INFO]),
        signs.numhl[vim.diagnostic.severity.INFO],
      },
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

commands['java.action.organizeImports.chooseImports'] = function(result)
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
        return {
          { selected and '*' or '', 'NonText' },
          item.fullyQualifiedName,
        }
      end

      local items = L.ui.pick(candidates, 'instant', format, {
        title = {
          {
            (' %s '):format(signs.text[vim.diagnostic.severity.INFO]),
            signs.numhl[vim.diagnostic.severity.INFO],
          },
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

commands['java.action.overrideMethodsPrompt'] = function(_, ctx)
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
  if not res or L.tbl.isempty(res.result.methods) then
    vim.notify('No overridable methods found', vim.log.levels.INFO)
    return
  end

  local function format(item, selected)
    return {
      { selected and '*' or '', 'NonText' },
      ('%s(%s) via %s'):format(
        item.name,
        table.concat(item.parameters, ', '),
        item.declaringClass
      ),
    }
  end

  local multi = {}
  for i = 1, #res.result.methods do
    if res.result.methods[i].declaringClass == 'java.lang.Object' then
      table.insert(multi, i)
    end
  end

  local items = L.ui.pick(res.result.methods, multi, format, {
    title = {
      {
        (' %s '):format(signs.text[vim.diagnostic.severity.INFO]),
        signs.numhl[vim.diagnostic.severity.INFO],
      },
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
  if L.tbl.isempty(res) then
    return
  end

  L.lsp.apply_edit(res[1])
end

--------------------------------------------------------------------------------

local handlers = {}

function handlers.definition(err, result, ctx, _)
  local uri, range =
    result.uri or result[1].uri, result.range or result[1].range
  if not vim.endswith(uri, '.class') then
    return { err = err, result = result }
  end

  if vim.startswith(uri, 'file://') then
    uri = vim.uri_from_fname(uri)
  end

  local params = { command = 'java.decompile', arguments = { uri } }
  err, result = L.lsp.request(
    vim.lsp.get_client_by_id(ctx.client_id) --[[@as vim.lsp.Client]],
    vim.lsp.protocol.Methods.workspace_executeCommand,
    params,
    ctx.bufnr
  )

  if err == nil then
    uri = uri:sub(0, ({ uri:find('^%w-://.-%.class%?') })[2] - 1)
    local bufnr = vim.uri_to_bufnr(uri)

    if vim.fn.bufloaded(bufnr) == 0 then
      vim.bo[bufnr].buftype = 'nowrite'
      vim.bo[bufnr].bufhidden = 'hide'
      vim.api.nvim_buf_set_name(bufnr, uri)
      vim.api.nvim_buf_set_lines(
        bufnr,
        0,
        -1,
        true,
        vim.split(result[1].result:gsub('\r\n', '\n'), '\n')
      )
    end

    result = { targetUri = uri, range = range }
  end

  return { err = err, result = result }
end

function handlers.execute_client_command(_, params, ctx)
  local cmd = (vim.lsp.get_client_by_id(ctx.client_id) or {}).commands or {}
  local _cmd = vim.tbl_extend('force', vim.lsp.commands, commands)
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

--------------------------------------------------------------------------------

for k, v in pairs(commands) do
  vim.lsp.commands[k] = v
end

local mpack = vim.fn.stdpath('data') .. '/mason/packages'
return {
  cmd = {
    'jdtls',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xms1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '--jvm-arg=-javaagent:' .. mpack .. '/jdtls/lombok.jar',
    '-jar',
    vim.fn.glob(mpack .. '/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
    '-configuration',
    mpack .. '/jdtls/config_linux',
    '-data',
    vim.fn.stdpath('data')
      .. '/jdtls-workspace/'
      .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:t'),
  },

  handlers = {
    ['language/status'] = function() end, -- disable status logging
    ['$/progress'] = function() end, -- disable progress logging
    ['textDocument/definition'] = handlers.definition,
    ['textDocument/typeDefinition'] = handlers.definition,
    ['workspace/executeClientCommand'] = (
      vim.lsp.handlers['workspace/executeClientCommand']
      or handlers.execute_client_command
    ),
  },

  -- https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  settings = { java = {} },

  init_options = {
    bundles = { vim.fn.glob(mpack .. '/java-test/extension/server/*.jar') },

    extendedClientCapabilities = {
      advancedOrganizeImportsSupport = true,
      classFileContentsSupport = true,
      executeClientCommandSupport = true,
      generateConstructorsPromptSupport = true,
      generateDelegateMethodsPromptSupport = true,
      generateToStringPromptSupport = true,
      hashCodeEqualsPromptSupport = true,
      overrideMethodsPromptSupport = true,
    },
  },

  capabilities = {
    textDocument = {
      codeAction = {
        codeActionLiteralSupport = {
          codeActionKind = {
            valueSet = {
              'source.generate.toString',
              'source.generate.hashCodeEquals',
              'source.organizeImports',
            },
          },
        },
      },
    },
  },
}

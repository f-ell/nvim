-- capabilities and extendedClientCapabilities via https://github.com/mfussenegger/nvim-jdtls
local mpc = vim.fn.stdpath('data') .. '/mason/packages'

for k, v in pairs(require('lsp.servers._jdtls').commands) do
  vim.lsp.commands[k] = v
end

local definition_handler = function(err, result, ctx, _)
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
    '--jvm-arg=-javaagent:' .. mpc .. '/jdtls/lombok.jar',
    '-jar',
    vim.fn.glob(mpc .. '/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
    '-configuration',
    mpc .. '/jdtls/config_linux',
    '-data',
    vim.fn.stdpath('data')
      .. '/jdtls-workspace/'
      .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:t'),
  },

  handlers = {
    ['language/status'] = function() end, -- disable prints
    ['$/progress'] = function() end, -- disable progress warnings
    ['textDocument/definition'] = definition_handler,
  },

  -- https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  settings = { java = {} },

  init_options = {
    bundles = { vim.fn.glob(mpc .. '/java-test/extension/server/*.jar') },

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

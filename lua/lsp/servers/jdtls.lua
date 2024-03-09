-- capabilities and extendedClientCapabilities via https://github.com/mfussenegger/nvim-jdtls
local mpc = vim.fn.stdpath('data') .. '/mason/packages'

for k, v in pairs(require('lsp.servers._jdtls').commands) do
  vim.lsp.commands[k] = v
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
  },

  -- https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  settings = { java = {} },

  init_options = {
    bundles = {
      vim.fn.glob(
        mpc
          .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'
      ),
      vim.fn.glob(mpc .. '/java-test/extension/server/*.jar'),
    },

    extendedClientCapabilities = {
      advancedExtractRefactoringSupport = true,
      advancedOrganizeImportsSupport = true,
      classFileContentsSupport = true,
      executeClientCommandSupport = true,
      generateConstructorsPromptSupport = true,
      generateDelegateMethodsPromptSupport = true,
      generateToStringPromptSupport = true,
      hashCodeEqualsPromptSupport = true,
      moveRefactoringSupport = true,
      overrideMethodsPromptSupport = true,
      inferSelectionSupport = {
        'extractMethod',
        'extractVariable',
        'extractConstant',
        'extractVariableAllOccurrence',
      },
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

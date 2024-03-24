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
    ['textDocument/definition'] = function(err, res, ctx)
      local uri, range = res.uri or res[1].uri, res.range or res[1].range
      if not vim.endswith(uri, '.class') then
        return { err = err, result = res }
      end

      if vim.startswith(uri, 'file://') then
        uri = vim.uri_from_fname(uri)
      end

      err, res = L.lsp.request(
        vim.lsp.get_client_by_id(ctx.client_id),
        'workspace/executeCommand',
        {
          command = 'java.decompile',
          arguments = { uri },
        },
        ctx.bufnr
      )

      if err == nil then
        uri = uri:sub(0, ({ uri:find('^%w-://.-%.class%?') })[2] - 1)
        local bufnr = vim.uri_to_bufnr(uri)

        if vim.fn.bufloaded(bufnr) == 0 then
          vim.bo[bufnr].buftype = 'nofile'
          vim.bo[bufnr].bufhidden = 'wipe'
          vim.api.nvim_buf_set_name(bufnr, uri)
          vim.api.nvim_buf_set_lines(
            bufnr,
            0,
            -1,
            true,
            vim.split(res[1].result:gsub('\r\n', '\n'), '\n')
          )
        end

        res = {
          targetUri = uri,
          range = range,
        }
      end

      return { err = err, result = res }
    end,
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

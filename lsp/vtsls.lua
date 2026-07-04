---@type vim.lsp.Config
return {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(
      bufnr,
      { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git', '.' }
    )

    if root and not vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc' }) then
      on_dir(root)
    end
  end,
  init_options = {
    hostInfo = 'neovim',
    preferences = {
      quotePreference = 'single',
    },
  },

  ---@type lspconfig.settings.vtsls
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = 'always' },
      suggest = {
        completeFunctionCalls = true,
      },
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = 'literals' },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
    },
  },
}

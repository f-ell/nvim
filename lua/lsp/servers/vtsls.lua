return {
  single_file_support = false,
  root_dir = function()
    return not vim.fs.root(0, { 'deno.json', 'deno.jsonc' })
      and vim.fs.root(
        0,
        { 'jsconfig.json', 'tsconfig.json', 'package.json', '.git', '.' }
      )
  end,
  init_options = {
    hostInfo = 'neovim',
    preferences = {
      quotePreference = 'single',
    },
  },
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

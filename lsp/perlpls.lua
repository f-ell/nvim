-- used solely for keyword completions
---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.perlpls
  settings = {
    perl = {
      perlcritic = { enabled = false },
      syntax = { enabled = false },
      perltidy = { enabled = false },
    },
  },
}

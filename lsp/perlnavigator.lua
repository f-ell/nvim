---@type vim.lsp.Config
return {
  cmd = { 'perlnavigator' },

  ---@type lspconfig.settings.perlnavigator
  settings = {
    perlnavigator = {
      perlPath = 'perl',
      perltidyProfile = '$workspaceFolder/.perltidyrc',
      perlcriticProfile = '$workspaceFolder/.perlcriticrc',
    },
  },
}

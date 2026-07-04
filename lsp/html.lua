---@type vim.lsp.Config
return {
  filetypes = { 'html', 'javascript', 'typescript', 'markdown' },

  ---@type lspconfig.settings.html
  settings = {
    html = {
      format = { enable = false },
      mirrorCursorOnMatchingTag = true,
    },
  },
}

---@type vim.lsp.Config
return {
  ---@type lspconfig.settings.zls
  settings = {
    zls = {
      enable_argument_placeholders = false,
      enable_build_on_save = true,
      highlight_global_var_declarations = true,
      warn_style = true,
    },
  },
}

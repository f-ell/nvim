---@type vim.lsp.Config
return {
  -- Configuration is only valid inside `settings`, despite what the lspconfig
  -- type information claims.
  ---@type _.lspconfig.settings.tinymist.Tinymist
  settings = {
    exportPdf = 'onSave',
    formatterPrintWidth = 80,
    formatterProseWrap = true,
    lint = {
      enabled = true,
      when = 'onType',
    },
    projectResolution = 'lockDatabase',
    typstExtraArgs = { '--input=img=0' },
  },
}

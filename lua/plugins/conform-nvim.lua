return {
  'stevearc/conform.nvim',
  lazy = true,
  event = 'BufWritePre',
  cmd = 'ConformInfo',
  opts = {
    formatters_by_ft = {
      css = { 'prettierd' },
      html = { 'prettierd' },
      javascript = { 'prettierd' },
      lua = { 'stylua' },
      typescript = { 'prettierd' },
      perl = { 'perltidy' },
    },
    formatters = {
      prettierd = { require_cwd = true },
      perltidy = { args = { '-pro=.../.perltidyrc' } },
    },
    format_on_save = {
      lsp_format = 'fallback',
      timeout_ms = 500,
      stop_after_first = true,
    },
  },
}

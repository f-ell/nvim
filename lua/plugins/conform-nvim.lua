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
    },
    formatters = {
      prettierd = { require_cwd = true },
    },
    format_on_save = {
      lsp_format = 'fallback',
      timeout_ms = 500,
      stop_after_first = true,
    },
    notify_on_error = true,
    notify_no_formatters = false,
  },
}

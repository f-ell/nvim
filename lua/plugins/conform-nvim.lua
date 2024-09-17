return {
  'stevearc/conform.nvim',
  lazy = true,
  event = 'BufWritePre',
  cmd = 'ConformInfo',
  config = function()
    require('conform').setup({
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
      },
      format_on_save = { lsp_format = 'fallback', timeout_ms = 750 },
      formatters = {
        prettierd = { require_cwd = true },
      },
      notify_on_error = true,
      notify_no_formatters = false,
    })
  end,
}

return {
  'folke/todo-comments.nvim',
  lazy = true,
  dependencies = 'nvim-lua/plenary.nvim',
  event = 'BufReadPost',
  opts = {
    signs = false,
    highlight = { multiline = true },
    keywords = {
      FIX = { icon = '•', color = 'error' },
      TODO = { icon = '•', color = 'info' },
      HACK = { icon = '•', color = 'warning' },
      WARN = { icon = '•', color = 'warning' },
      PERF = { icon = '•', color = 'test' },
      NOTE = { icon = '•', color = 'hint' },
      TEST = { icon = '•', color = 'test' },
    },
    colors = { test = { 'DiagnosticOk' } },
  },
}

return {
  'folke/todo-comments.nvim',
  lazy = true,
  dependencies = 'nvim-lua/plenary.nvim',
  event = 'BufReadPost',
  opts = {
    signs = false,
    highlight = { multiline = true },
    keywords = {
      FIX = { color = 'error' },
      TODO = { color = 'info' },
      HACK = { color = 'warning' },
      WARN = { color = 'warning' },
      PERF = { color = 'performance' },
      NOTE = { color = 'hint' },
      TEST = { color = 'test' },
    },
    colors = { performance = { 'DiagnosticOk' } },
  },
}

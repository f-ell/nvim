return {
  'folke/todo-comments.nvim',
  lazy = true,
  dependencies = 'nvim-lua/plenary.nvim',
  event = 'BufReadPost',
  config = function()
    require('todo-comments').setup({
      signs = false,
      highlight = { multiline = true },
      keywords = {
        FIX = {
          icon = '• ',
          color = 'error',
          alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' },
        },
        TODO = { icon = '• ', color = 'info' },
        HACK = { icon = '• ', color = 'warning' },
        WARN = { icon = '• ', color = 'warning', alt = { 'WARNING' } },
        PERF = {
          icon = '• ',
          color = 'performance',
          alt = { 'OPTIM', 'OPTIMIZE', 'PERFORMANCE' },
        },
        NOTE = { icon = '• ', color = 'hint', alt = { 'INFO' } },
        TEST = {
          icon = '• ',
          color = 'test',
          alt = { 'TESTING', 'PASSED', 'FAILED' },
        },
      },
      colors = {
        performance = { 'DiagnosticOk' },
      },
    })
  end,
}

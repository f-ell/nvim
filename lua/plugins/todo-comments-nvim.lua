return {
  'folke/todo-comments.nvim',
  lazy = true,
  dependencies = 'nvim-lua/plenary.nvim',
  cmd = 'TodoTelescope',
  event = 'BufReadPost',
  keys = {
    { '<leader>tt', '<CMD>TodoTelescope<CR>' },
  },
  opts = {
    signs = false,
    highlight = {
      multiline = false,
      after = '',
    },
    keywords = {
      FIX = { icon = '•', color = 'error' },
      TODO = { icon = '•', color = 'info' },
      HACK = { icon = '•', color = 'warning' },
      WARN = { icon = '•', color = 'warning' },
      PERF = { icon = '•', color = 'test' },
      NOTE = { icon = '•', color = 'hint' },
      TEST = { icon = '•', color = 'test' },
    },
  },
}

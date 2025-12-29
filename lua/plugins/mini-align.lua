return {
  'nvim-mini/mini.align',
  lazy = true,
  keys = {
    { '<leader>a', mode = { 'n', 'v' } },
    { '<leader>A', mode = { 'n', 'v' } },
  },
  opts = {
    mappings = { start = '<leader>a', start_with_preview = '<leader>A' },
  },
}

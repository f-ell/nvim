return {
  'echasnovski/mini.align',
  lazy = true,
  keys = { '<leader>a', '<leader>A' },
  config = function()
    require('mini.align').setup({
      mappings = {
        start = '<leader>a',
        start_with_preview = '<leader>A'
      }
    })
  end
}

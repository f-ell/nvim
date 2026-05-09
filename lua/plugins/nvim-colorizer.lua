return {
  'catgoose/nvim-colorizer.lua',
  lazy = true,
  event = 'BufReadPost',
  keys = { { '<leader>ct', '<CMD>ColorizerToggle<CR>' } },
  opts = {
    filetypes = { '*' },
    user_default_options = {
      css = true,
      names = false,
      AARRGGBB = true,
      mode = 'virtualtext',
      virtualtext = '■',
      virtualtext_inline = true,
    },
  },
}

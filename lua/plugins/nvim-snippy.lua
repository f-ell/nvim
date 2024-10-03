return {
  'dcampos/nvim-snippy',
  lazy = true,
  dependencies = 'dcampos/cmp-snippy',
  opts = {
    enable_auto = true,
    mappings = {
      [{ 'i', 's' }] = {
        ['<C-l>'] = 'expand_or_advance',
        ['<C-h>'] = 'previous',
      },
    },
  },
}

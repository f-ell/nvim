return {
  'echasnovski/mini.surround',
  lazy = true,
  keys = {
    { '<leader>s', mode = { 'n', 'v' } },
    'cs',
    'ds',
    '<leader><leader>s',
    '<leader>ns',
  },
  opts = {
    custom_surroundings = nil,
    n_lines = 20,
    search_method = 'cover_or_nearest',
    mappings = {
      add = '<leader>s',
      replace = 'cs',
      delete = 'ds',
      find = '',
      find_left = '',
      highlight = '',
      update_n_lines = '',

      suffix_last = 'l',
      suffix_next = 'n',
    },
  },
}

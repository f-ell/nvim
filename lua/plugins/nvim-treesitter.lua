return {
  'nvim-treesitter/nvim-treesitter',
  lazy = true,
  event = { 'BufNewFile', 'BufReadPost' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    {
      'JoosepAlviste/nvim-ts-context-commentstring',
      opts = { enable = true, enable_autocmd = false },
    },
    {
      'nvim-treesitter/nvim-treesitter-context',
      opts = {
        enable = true,
        mode = 'cursor',
        trim_scope = 'outer',
        max_lines = 4,
        min_window_height = 24,
      },
    },
  },
  opts = {
    auto_install = false,
    sync_install = false,
    ensure_installed = {},
    ignore_install = {},
    modules = {},

    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },

    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        include_surrounding_whitespace = true,
        keymaps = {
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['ac'] = '@conditional.outer',
          ['ic'] = '@conditional.inner',
          ['al'] = '@loop.outer',
          ['il'] = '@loop.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['aC'] = '@class.outer',
          ['iC'] = '@class.inner',
        },
      },
    },
  },
  config = function(spec)
    require('nvim-treesitter.configs').setup(spec.opts)

    vim.o.foldmethod = 'expr'
    vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
  end,
}

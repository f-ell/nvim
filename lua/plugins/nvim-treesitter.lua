return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  dependencies = {
    {
      'nvim-treesitter/nvim-treesitter-textobjects',
      branch = 'main',
      opts = {
        select = {
          lookahead = true,
          include_surrounding_whitespace = true,
        },
      },
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
  build = ':TSUpdate',
  config = function()
    vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.o.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"

    ---@param key string
    ---@param obj string
    local register = function(key, obj)
      L.key.modemap({ 'x', 'o' }, key, function()
        require('nvim-treesitter-textobjects.select').select_textobject(
          obj,
          'textobjects'
        )
      end)
    end

    register('aa', '@parameter.outer')
    register('ia', '@parameter.inner')
    register('ac', '@conditional.outer')
    register('ic', '@conditional.inner')
    register('al', '@loop.outer')
    register('il', '@loop.inner')
    register('af', '@function.outer')
    register('if', '@function.inner')
    register('aC', '@class.outer')
    register('iC', '@class.inner')
  end,
}

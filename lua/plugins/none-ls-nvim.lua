return {
  'nvimtools/none-ls.nvim',
  lazy = true,
  event = { 'BufNewFile', 'BufReadPost' },
  dependencies = 'nvim-lua/plenary.nvim',
  config = function()
    local null = require('null-ls')
    local sources = {
      eslint_d = {
        command = 'eslint_d',
        condition = function(utils)
          return utils.root_has_file({
            '.eslintrc.js',
            '.eslintrc.json',
            '.eslintrc.yml',
          })
        end,
      },
      prettier_d = {
        command = 'prettierd',
        condition = function(utils)
          return utils.root_has_file({
            '.prettierrc',
            '.prettierrc.js',
            '.prettierrc.json',
            '.prettierrc.yml',
          })
        end,
      },
      stylua = {
        command = 'stylua',
      },
    }

    null.setup({
      on_attach = function(_, bufnr)
        vim.api.nvim_create_autocmd('BufWritePre', {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({
              filter = function(c)
                return c.name == 'null-ls'
              end,
            })
          end,
        })
      end,

      sources = {
        null.builtins.code_actions.eslint_d.with(sources.eslint_d),
        null.builtins.diagnostics.eslint_d.with(sources.eslint_d),
        null.builtins.formatting.prettierd.with(sources.prettier_d),
        null.builtins.formatting.stylua.with(sources.stylua),
      },
    })
  end,
}

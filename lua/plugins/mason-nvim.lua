return {
  'williamboman/mason.nvim',
  lazy = true,
  cmd = 'Mason',
  event = { 'BufReadPost', 'BufNewFile', 'BufFilePost' },
  dependencies = { 'neovim/nvim-lspconfig', 'saghen/blink.cmp' },
  init = function()
    -- Loading the user's `lsp/` first prevents making changes to nvim-lspconfig
    -- default configurations. This swaps the order to allow overwriting
    -- defaults from `lsp/`, instead of having to rely on `after/lsp/`.
    vim.opt.runtimepath:prepend(
      ('%s/lazy/nvim-lspconfig'):format(vim.fn.stdpath('data'))
    )

    if vim.fn.argc() ~= 0 then
      require('mason')
    end
  end,
  config = function()
    vim.diagnostic.config({
      update_in_insert = true,
      underline = true,
      virtual_text = false,
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = '•',
          [vim.diagnostic.severity.WARN] = '•',
          [vim.diagnostic.severity.INFO] = '•',
          [vim.diagnostic.severity.HINT] = '•',
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
          [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
          [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
          [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
        },
      },
    })

    require('mason').setup({ ui = { border = 'single' } })

    local key = require('lib').key
    local lsp = require('lsp')
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp', {}),
      callback = function(args)
        key.nnmap('grf', function()
          require('conform').format({
            timeout_ms = 500,
            lsp_format = 'fallback',
          })
        end, { buffer = args.buf })
        key.nnmap('gd', lsp.def.peek, { buffer = args.buf })
        key.nnmap('grd', lsp.def.open, { buffer = args.buf })
        key.nnmap('grt', lsp.def.type, { buffer = args.buf })

        key.nnmap('gra', lsp.cda.codeaction, { buffer = args.buf })
        key.nnmap('grn', lsp.ren.rename, { buffer = args.buf })
        key.nnmap('grr', vim.lsp.buf.references, { buffer = args.buf })
        key.modemap(
          { 'i', 'n' },
          '<C-s>',
          lsp.sig.active,
          { buffer = args.buf }
        )
        key.modemap(
          { 'i', 'n' },
          '<C-S-s>',
          lsp.sig.available,
          { buffer = args.buf }
        )

        key.nnmap('grh', function()
          vim.lsp.buf.document_highlight()
          vim.api.nvim_create_autocmd('CursorMoved', {
            buffer = 0,
            callback = function()
              local ns = vim.api.nvim_get_namespaces()['nvim.lsp.references']
              vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
            end,
            once = true,
          })
        end, { buffer = args.buf })

        key.nnmap('<leader>h', lsp.dgn.get_line, { buffer = args.buf })
        key.nnmap('<leader>j', function()
          lsp.dgn.get_dir('next')
        end, { buffer = args.buf })
        key.nnmap('<leader>k', function()
          lsp.dgn.get_dir('prev')
        end, { buffer = args.buf })
        key.nnmap('<leader>l', function()
          require('telescope.builtin').diagnostics({ bufnr = args.buf })
        end)
      end,
    })

    vim
      .iter(require('mason-registry').get_installed_packages())
      :filter(function(p)
        ---@cast p Package
        ---@diagnostic disable-next-line: undefined-field
        return p.spec.neovim ~= nil
      end)
      :map(function(p)
        ---@cast p Package
        ---@diagnostic disable-next-line: undefined-field
        return p.spec.neovim.lspconfig
      end)
      :each(function(s)
        vim.lsp.config(
          s,
          { capabilities = require('blink.cmp').get_lsp_capabilities() }
        )
        vim.lsp.enable(s)
      end)
  end,
}

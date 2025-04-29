return {
  'williamboman/mason.nvim',
  lazy = true,
  cmd = 'Mason',
  event = { 'BufReadPost', 'BufNewFile', 'BufFilePost' },
  dependencies = { 'neovim/nvim-lspconfig', 'saghen/blink.cmp' },
  init = function()
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
    local ui = require('lsp.ui')
    local on_attach = function()
      key.nnmap('<leader>fb', function()
        require('conform').format({ timeout_ms = 500, lsp_format = 'fallback' })
      end, { buffer = true })
      key.nnmap('gr', vim.lsp.buf.references, { buffer = true })
      key.nnmap('gd', ui.def.peek, { buffer = true })
      key.nnmap('<leader>gd', ui.def.open, { buffer = true })
      key.nnmap('<leader>gt', ui.def.type, { buffer = true })

      key.nnmap('<leader>ca', ui.cda.codeaction, { buffer = true })
      key.nnmap('<leader>rn', ui.ren.rename, { buffer = true })
      key.modemap({ 'i', 'n' }, '<C-s>', ui.sig.active)
      key.modemap({ 'i', 'n' }, '<C-S-s>', ui.sig.available)

      key.nnmap('<leader>h', ui.dgn.get_line, { buffer = true })
      key.nnmap('<leader>j', function()
        ui.dgn.get_dir('next')
      end, { buffer = true })
      key.nnmap('<leader>k', function()
        ui.dgn.get_dir('prev')
      end, { buffer = true })
      key.nnmap('<leader>l', function()
        require('telescope.builtin').diagnostics({ bufnr = true })
      end)
    end

    local servers = vim
      .iter(vim.fn.readdir(vim.fn.stdpath('config') .. '/lua/lsp/servers'))
      :filter(function(s)
        return not vim.startswith(s, '_')
      end)
      :totable()

    for i = 1, #servers do
      local server = servers[i]:gsub('%.lua$', '')
      local cfg = {
        on_attach = on_attach,
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      }

      local ok, tbl = pcall(require, 'lsp.servers.' .. server)
      if ok then
        cfg = vim.tbl_deep_extend('force', cfg, tbl)
      end

      require('lspconfig')[server].setup(cfg)
    end
  end,
}

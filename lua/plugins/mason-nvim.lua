return {
  'williamboman/mason.nvim',
  lazy = true,
  cmd = 'Mason',
  event = { 'BufReadPost', 'BufNewFile', 'BufFilePost' },
  dependencies = { 'hrsh7th/cmp-nvim-lsp', 'neovim/nvim-lspconfig' },
  init = function()
    if vim.fn.argc() ~= 0 then
      require('mason')
    end
  end,
  config = function()
    local signs = {
      { 'DiagnosticSignError', '•' },
      { 'DiagnosticSignWarn', '•' },
      { 'DiagnosticSignInfo', '•' },
      { 'DiagnosticSignHint', '•' },
    }
    for i = 1, #signs do
      vim.fn.sign_define(
        signs[i][1],
        { texthl = signs[i][1], text = signs[i][2] }
      )
    end

    vim.diagnostic.config({
      update_in_insert = true,
      underline = true,
      virtual_text = false,
      severity_sort = true,
      sign = { active = signs },
    })

    vim.lsp.handlers[vim.lsp.protocol.Methods.textDocument_hover] =
      vim.lsp.with(vim.lsp.handlers.hover, { border = 'single' })

    require('mason').setup({ ui = { border = 'single' } })

    local key = require('lib').key
    local ui = require('lsp.ui')
    local on_attach = function()
      key.nnmap('<leader>fb', function()
        require('conform').format({ timeout_ms = 500, lsp_format = 'fallback' })
      end, { buffer = true })
      key.nnmap('<leader>rf', vim.lsp.buf.references, { buffer = true })

      key.nnmap('gd', ui.def.peek, { buffer = true })
      key.nnmap('<leader>gd', ui.def.open, { buffer = true })
      key.nnmap('<leader>gt', ui.def.type, { buffer = true })

      key.nnmap('<leader>ca', ui.cda.codeaction, { buffer = true })
      key.nnmap('<leader>rn', ui.ren.rename, { buffer = true })
      key.modemap({ 'i', 'n' }, '<C-s>', ui.sig.active)
      key.modemap({ 'i', 'n' }, '<C-A-s>', ui.sig.available)

      key.nnmap('<leader>h', ui.dgn.get_line, { buffer = true })
      key.nnmap('<leader>j', ui.dgn.goto_next, { buffer = true })
      key.nnmap('<leader>k', ui.dgn.goto_prev, { buffer = true })
      key.nnmap('<leader>l', function()
        require('telescope.builtin').diagnostics({ bufnr = true })
      end)
    end

    local capabilities = require('cmp_nvim_lsp').default_capabilities(
      vim.lsp.protocol.make_client_capabilities()
    )

    local servers = vim.tbl_filter(function(s)
      return not vim.startswith(s, '_')
    end, vim.fn.readdir(vim.fn.stdpath('config') .. '/lua/lsp/servers'))

    for i = 1, #servers do
      local opts = { on_attach = on_attach, capabilities = capabilities }
      local server = servers[i]:gsub('%.lua$', '')

      local req, tbl = pcall(require, 'lsp.servers.' .. server)
      if req then
        opts = vim.tbl_deep_extend('force', opts, tbl)
      end
      require('lspconfig')[server].setup(opts)
    end
  end,
}

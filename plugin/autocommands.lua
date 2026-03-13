vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResume' }, {
  callback = function()
    vim.opt.guicursor = {
      'n-v-c-sm:block',
      'i-ci-ve:hor1-blinkon200-blinkoff150',
      'r-cr-o:hor20',
    }
  end,
})
vim.api.nvim_create_autocmd({ 'VimLeave', 'VimSuspend' }, {
  callback = function()
    vim.opt.guicursor = {}
    vim.fn.chansend(vim.v.stderr, '\x1b[ q')
    vim.cmd.sleep('1ms') -- Sleep is required to work correctly on suspend.
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank({
      higroup = 'Visual',
      on_macro = true,
      on_visual = false,
    })
  end,
})

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    require('colors'):set()
  end,
})

-- https://github.com/nvim-telescope/telescope.nvim/issues/3436#issuecomment-2756267300
vim.api.nvim_create_autocmd('User', {
  pattern = 'TelescopeFindPre',
  callback = function()
    local border = vim.o.winborder
    vim.opt_local.winborder = 'none'
    vim.api.nvim_create_autocmd('WinLeave', {
      once = true,
      callback = function()
        vim.opt_local.winborder = border
      end,
    })
  end,
})

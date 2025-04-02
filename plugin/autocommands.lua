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
    vim.opt_local.winborder = 'none'
    vim.api.nvim_create_autocmd('WinLeave', {
      once = true,
      callback = function()
        vim.opt_local.winborder = vim.o.winborder
      end,
    })
  end,
})

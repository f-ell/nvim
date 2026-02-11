-- bootstrap
local std = vim.fn.stdpath
local path = std('data') .. '/lazy/lazy.nvim'

if not vim.uv.fs_stat(path) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--single-branch',
    'https://github.com/folke/lazy.nvim.git',
    path,
  })
end

-- init
L = require('lib')

vim.g.mapleader = ' '
vim.opt.runtimepath:prepend(path)

require('lazy').setup('plugins', {
  root = std('data') .. '/lazy',
  install = { missing = true },
  checker = { enabled = false },
  ui = { border = 'single' },
  performance = {
    cache = {
      enabled = true,
      path = std('cache') .. '/lazy/cache',
    },
  },
  change_detection = { notify = false },
})

vim.o.termguicolors = true
vim.api.nvim_command('filetype plugin indent on')

vim.cmd.colorscheme('leafless')

-- FIX: deprecate once https://github.com/neovim/neovim/pull/33145 is merged
vim.g._ts_force_sync_parsing = true -- see 32660

vim.o.showcmd = false
vim.o.showmode = false
vim.o.textwidth = 80
vim.o.wrap = false

vim.o.confirm = true
vim.o.cursorline = true
vim.o.inccommand = 'split'

vim.o.cmdheight = 1
vim.o.pumheight = 7
vim.o.scrolloff = 1
vim.o.sidescrolloff = 1
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.shortmess = 'asWFS'
vim.o.mousemodel = 'extend'

vim.opt.jumpoptions = { 'stack', 'view' }
vim.opt.fillchars = {
  diff = '╱',
  foldopen = '┌',
  foldclose = '›',
  foldsep = '│',
}

vim.o.list = true
vim.o.showbreak = '> '
vim.opt.listchars = {
  eol = '¬',
  tab = '| ',
  lead = '.',
  trail = '~',
  nbsp = '+',
  extends = '›',
  precedes = '‹',
}

vim.opt.spelllang = { 'en_gb', 'de_de' }
vim.opt.nrformats = { 'bin', 'hex', 'blank' }
vim.opt.diffopt = {
  'internal',
  'algorithm:histogram',
  'filler',
  'closeoff',
  'linematch:60',
  'foldcolumn:0',
}

-- tabs
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2

-- timeout
vim.o.timeoutlen = 500
vim.o.ttimeoutlen = 0

-- windows
vim.o.winborder = 'single'
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.equalalways = false

-- buffers
vim.o.autochdir = true
vim.o.undofile = true

-- folds
vim.o.foldtext = ''
vim.o.foldlevel = 1
vim.o.foldnestmax = 3

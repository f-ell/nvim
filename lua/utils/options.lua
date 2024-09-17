-- spelling
vim.opt.spelllang = { 'en_gb', 'de_de' }

-- miscellaneous
vim.o.shell = 'dash'
vim.o.cdhome = true
vim.o.confirm = true
vim.o.showmode = false
vim.o.showcmd = false
vim.o.showbreak = '> '
vim.o.cmdheight = 1

vim.o.list = true
vim.o.sidescrolloff = 1
vim.opt.listchars = {
  eol = '¬',
  tab = '| ',
  lead = '.',
  trail = '~',
  nbsp = '+',
  extends = '',
  precedes = '',
}
vim.opt.fillchars = {
  diff = '╱',
  foldopen = '',
  foldclose = '',
}
vim.opt.jumpoptions = { 'stack', 'view' }

vim.o.cursorline = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.shortmess = 'asWFS'

vim.o.wrap = false
vim.o.textwidth = 80
vim.o.number = true
vim.o.relativenumber = true
vim.o.pumheight = 7

vim.o.clipboard = 'unnamed'
vim.opt.guicursor = {
  'n-v-c-sm:block',
  'i-ci-ve:hor1-blinkon200-blinkoff150',
  'r-cr-o:hor20',
}
vim.o.scrolloff = 1
vim.o.mouse = 'a'

-- tab-settings
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2

-- timeouts
vim.o.timeoutlen = 500
vim.o.ttimeoutlen = 0

-- splits
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.equalalways = false
vim.o.ruler = false

-- buffers
vim.o.autochdir = true
vim.o.updatecount = 0
vim.o.undofile = true

-- folds
vim.o.foldlevel = 0
_G.user_foldtext = function()
  local count = vim.v.foldend - vim.v.foldstart + 1
  local ln = vim.fn.trim(vim.fn.getline(vim.v.lnum))

  if vim.o.foldmethod == 'marker' then
    local cs = vim.o.commentstring:sub(0, vim.o.commentstring:find('%%s') - 1)
    local fm = vim.o.foldmarker:sub(0, vim.o.foldmarker:find(',') - 1)

    if vim.startswith(ln, cs) then
      ln = vim.fn.trim(ln:sub(cs:len()))
      ln = vim.fn.trim(ln:sub(0, ln:find(fm) - 1), '', 2)
    else
      ln = ln:sub(0, ln:find(cs .. '%s*' .. fm .. '%d*$') - 1)
    end
  end

  return count .. ' ln: ' .. ln .. ' '
end
vim.o.foldtext = 'v:lua.user_foldtext()'

-- transparency
vim.o.pumblend = 0
vim.o.winblend = 0

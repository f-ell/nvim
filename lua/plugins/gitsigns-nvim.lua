local winopts = {
  statuscolumn = nil,
  signcolumn = nil,
  number = nil,
  relativenumber = nil,
}

local toggle_diff = function()
  if not vim.wo.diff then
    winopts = {
      statuscolumn = vim.wo.statuscolumn,
      signcolumn = vim.wo.signcolumn,
      number = vim.wo.number,
      relativenumber = vim.wo.relativenumber,
    }

    require('gitsigns').diffthis()
    for _, win in pairs(vim.api.nvim_tabpage_list_wins(0)) do
      vim.wo[win].statuscolumn = ''
      vim.wo[win].signcolumn = 'no'
      -- vim.wo[win].number = false
      -- vim.wo[win].relativenumber = false
    end
    return
  end

  -- WARN: will break with simultaneous diffs
  for _, win in pairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.fn.bufname(vim.fn.winbufnr(win)):match('^gitsigns://.-') then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.wo.statuscolumn = winopts.statuscolumn
  vim.wo.signcolumn = winopts.signcolumn
  vim.wo.number = winopts.number
  vim.wo.relativenumber = winopts.relativenumber
end

return {
  'lewis6991/gitsigns.nvim',
  lazy = true,
  event = 'BufReadPost',
  keys = {
    { 'gsk', '<CMD>silent Gitsigns nav_hunk prev<CR>zz' },
    { 'gsJ', '<CMD>silent Gitsigns nav_hunk next target=staged<CR>zz' },
    { 'gsh', toggle_diff },
    { 'gsj', '<CMD>silent Gitsigns nav_hunk next<CR>zz' },
    { 'gsK', '<CMD>silent Gitsigns nav_hunk prev target=staged<CR>zz' },
    { 'gsl', '<CMD>Gitsigns toggle_deleted<CR>' },
    { 'gsc', '<CMD>Gitsigns toggle_linehl<CR>' },
    { 'gsv', '<CMD>Gitsigns select_hunk<CR>' },
    { 'gs<', '<CMD>diffget gitsigns://*:0\\\\|2:<CR>' },
    { 'gs>', '<CMD>diffget gitsigns://*:3:<CR>' },
  },
  opts = {
    signs = {
      add = { text = '│' },
      change = { text = '│' },
      delete = { text = '│' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
    signs_staged = {
      add = { text = '│' },
      change = { text = '│' },
      delete = { text = '│' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },

    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,

    watch_gitdir = {
      interval = 500,
      follow_files = true,
    },
  },
}

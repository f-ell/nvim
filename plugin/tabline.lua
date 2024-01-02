local L = require('lib')

local tabline = function()
  local tabs = {}

  for i = 1, vim.fn.tabpagenr('$') do
    local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    local name = vim.fn.bufname(bufnr)
    name = name == '' and '[null]' or (name:match('([^/]-/?)$') or '_ERR')

    local tab = {
      string.format('%%%sT', i),
      '%#Tab' .. (i == vim.fn.tabpagenr() and 'Active' or 'Inactive') .. '#',
      '▎',
      vim.api.nvim_buf_get_option(bufnr, 'modified') and ' + ' or '  ',
      name .. '  ',
    }

    table.insert(tabs, table.concat(tab))
  end

  return table.concat(tabs) .. '%#TabInactive#'
end

_G.tabline = tabline
vim.o.showtabline = 1
vim.o.tabline = '%!v:lua.tabline()'

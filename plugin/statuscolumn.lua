local lnum = function()
  if vim.v.virtnum ~= 0 then
    return ''
  end
  return vim.v.relnum == 0 and vim.v.lnum .. ' ' or vim.v.relnum
end

_G.user_sc = function()
  return '%C%=' .. lnum() .. ' %s'
end

vim.o.foldcolumn = 'auto:1'
vim.o.numberwidth = 2
vim.o.signcolumn = 'yes:1'
vim.o.statuscolumn = '%!v:lua.user_sc()'

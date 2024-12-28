if vim.fn.expand('%:e') == 'sty' then
  return
end

vim.o.spell = true
vim.opt.formatoptions:append('or')

vim.api.nvim_buf_create_user_command(
  0,
  'AlignTable',
  'norm vie<leader>as&<CR>',
  {}
)

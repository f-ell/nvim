if vim.fn.expand('%:e') == 'sty' then
  return
end

vim.wo[0][0].spell = true

vim.api.nvim_buf_create_user_command(
  0,
  'AlignTable',
  'norm vie<leader>as&<CR>',
  {}
)

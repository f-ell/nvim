vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank({
      higroup = 'Visual',
      on_macro = true,
      on_visual = false,
    })
  end,
})

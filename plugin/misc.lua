L = require('lib')

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank({
      higroup = 'Search',
      timeout = 140,
      on_visual = false,
    })
  end,
})

vim.filetype.add({
  extension = {
    snippet = 'snippet',
    snippets = 'snippet',
  },
})

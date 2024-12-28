return {
  'numToStr/Comment.nvim',
  lazy = true,
  keys = {
    'm',
    { '<leader>m', mode = { 'n', 'v' } },
  },
  opts = {
    sticky = true,
    padding = true,
    mappings = { basic = true, extra = false },
    toggler = { line = 'm' },
    opleader = { line = '<leader>m' },
    pre_hook = function()
      require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
    end,
  },
}

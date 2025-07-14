return {
  'numToStr/Comment.nvim',
  lazy = true,
  keys = { 'gc', 'gcc', 'gb', 'gbc' },
  opts = {
    sticky = true,
    padding = true,
    mappings = { basic = true, extra = false },
    pre_hook = function()
      require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
    end,
  },
}

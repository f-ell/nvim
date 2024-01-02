return {
  'mbbill/undotree',
  lazy = true,
  cmd = 'UndotreeToggle',
  config = function()
    local L = require('lib')
    L.vim.g('undotree_SetFocusWhenToggle', 1)
    L.vim.g('undotree_ShortIndicators', 1)
    L.vim.g('undotree_DiffpanelHeight', 16)
    L.vim.g('undotree_HelpLine', 0)
  end,
}

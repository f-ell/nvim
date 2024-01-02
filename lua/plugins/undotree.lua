return {
  'mbbill/undotree',
  lazy = true,
  cmd = 'UndotreeToggle',
  config = function()
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_DiffpanelHeight = 16
    vim.g.undotree_HelpLine = 0
  end,
}

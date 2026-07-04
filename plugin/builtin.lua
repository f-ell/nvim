local builtins = {
  'man',
  'netrwPlugin',
  'remote_plugins',
  'shada_plugin',
  'tutor_mode_plugin',
}

for _, plugin in pairs(builtins) do
  vim.g['loaded_' .. plugin] = true
end

vim.cmd.packadd('nvim.undotree')

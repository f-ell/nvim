local builtins = {
  'man',
  'matchparen',
  'netrwPlugin',
  'remote_plugins',
  'shada_plugin',
  '2html_plugin',
  'tutor_mode_plugin',
}

for _, plugin in pairs(builtins) do
  vim.g['loaded_' .. plugin] = true
end

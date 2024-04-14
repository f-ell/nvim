local key = L.key

key.nnmap('--', '<CMD>w<CR>')
key.nnmap('<leader>~', 'viw~')
key.nnmap('<leader>w', '<CMD>w !doas tee %<CR>')
key.nnmap('<leader>x', '<CMD>!chmod 744 %<CR>')
key.nnmap('<leader>%', '<CMD>so %<CR>')

key.tnmap('<C-d>', '<C-\\><C-n>')

key.nnmap('n', 'nzz')
key.nnmap('N', 'Nzz')
key.nnmap('<C-u>', '<C-u>zz')
key.nnmap('<C-d>', '<C-d>zz')
key.modemap({ 'n', 'v' }, '<leader>y', '"+y')
key.modemap({ 'n', 'v' }, '<leader>d', '"_d')

-- qf / loc
key.nnmap('<leader>cj', function()
  return '<CMD>' .. vim.v.count .. 'cnext<CR>'
end, { expr = true })
key.nnmap('<leader>ck', function()
  return '<CMD>' .. vim.v.count .. 'cprev<CR>'
end, { expr = true })
key.nnmap('<leader>co', '<CMD>copen<CR>')
key.nnmap('<leader>cc', '<CMD>cclose<CR>')

-- ex
key.cnmap('<A-h>', '<Left>')
key.cnmap('<A-k>', '<Up>')
key.cnmap('<A-j>', '<Down>')
key.cnmap('<A-l>', '<Right>')
key.cnmap('<A-S-h>', '<C-Left>')
key.cnmap('<A-S-l>', '<C-Right>')

-- windows
key.nnmap('<A-h>', '<C-w>h')
key.nnmap('<A-j>', '<C-w>j')
key.nnmap('<A-k>', '<C-w>k')
key.nnmap('<A-l>', '<C-w>l')

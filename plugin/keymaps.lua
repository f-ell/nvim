local key = L.key

key.modemap({ 'n', 'i' }, '<C-.>', require('emmet').expand_word)
key.vnmap('<leader>*', function()
  local base = os.getenv('XGD_PICTURES_HOME')
    or os.getenv('HOME') .. '/Pictures'

  require('silicon'):screenshot({
    directory = base .. '/Screenshots/Code/',
    font = 'Ellograph CF',
  })
end)

key.nnmap('<leader>w', '<CMD>w !doas tee %<CR>')
key.nnmap('<leader>x', '<CMD>!chmod u+x %<CR>')

key.tnmap('<C-d>', '<C-\\><C-n>')

key.nnmap('n', 'nzz')
key.nnmap('N', 'Nzz')
key.nnmap('<C-u>', '<C-u>zz')
key.nnmap('<C-d>', '<C-d>zz')
key.modemap({ 'n', 'v' }, '<leader>y', '"+y')
key.modemap({ 'n', 'v' }, '<leader>p', '"+p')
key.modemap({ 'n', 'v' }, '<leader>d', '"_d')

-- qf / loc
key.nnmap('<leader>co', '<CMD>copen<CR>')
key.nnmap('<leader>cc', '<CMD>cclose<CR>')

-- This overwrites the builtin `zi`, which usually doesn't trigger an
-- `OptionSet` event. Triggering the event is necessary to update the foldcolumn
-- width. The relevant autocommand can be found in the statuscolumn definition.
L.key.nnmap('zi', function()
  vim.wo.foldenable = not vim.wo.foldenable
end)

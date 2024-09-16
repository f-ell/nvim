local key = L.key

local function dec2hex()
  vim.api.nvim_feedkeys('viw', 'x', false)

  local s_pos = vim.fn.getpos('v')
  local e_pos = vim.fn.getpos('.')
  if s_pos[2] < e_pos[2] or (s_pos[2] == e_pos[2] and s_pos[3] > e_pos[3]) then
    s_pos, e_pos = e_pos, s_pos
  end

  vim.api.nvim_buf_set_text(
    s_pos[1],
    s_pos[2] - 1,
    s_pos[3] - 1,
    e_pos[2] - 1,
    e_pos[3],
    { ('0x%02x'):format(vim.fn.expand('<cword>')) }
  )

  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes('<ESC>', true, false, true),
    'x',
    false
  )
  vim.fn.cursor(s_pos[2], s_pos[3])
end

key.nnmap('<leader>dh', dec2hex)

key.nnmap('--', '<CMD>w<CR>')
key.nnmap('<leader>w', '<CMD>w !doas tee %<CR>')
key.nnmap('<leader>x', '<CMD>!chmod u+x %<CR>')
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

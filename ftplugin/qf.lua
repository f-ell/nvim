L.key.nnmap('<C-j>', function()
  if vim.fn.getpos('.')[2] == vim.fn.line('$') then
    return
  end

  vim.cmd('silent ' .. vim.v.count .. 'cnext | wincmd p')
end, { buffer = true })

L.key.nnmap('<C-k>', function()
  if vim.fn.getpos('.')[2] == 1 then
    return
  end

  vim.cmd('silent ' .. vim.v.count .. 'cprev | wincmd p')
end, { buffer = true })

vim.wo[0][0].spell = true

local MAXW = 9999
local tw = vim.bo.textwidth

vim.api.nvim_create_autocmd('BufEnter', {
  buffer = vim.api.nvim_get_current_buf(),
  callback = function()
    if vim.bo.textwidth == MAXW then
      return
    end

    tw = vim.bo.textwidth
  end,
})

local q = vim.treesitter.query.parse('markdown', '(pipe_table) @table')

vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
  buffer = vim.api.nvim_get_current_buf(),
  callback = function()
    local t = vim.treesitter.get_parser():parse()[1]
    local pos = vim.fn.getpos('.')

    local b = vim.iter(q:iter_captures(t:root(), 0)):any(
      ---@param id integer
      ---@param node TSNode
      ---@param meta vim.treesitter.query.TSMetadata
      ---
      ---@diagnostic disable-next-line: unused-local
      function(id, node, meta)
        return vim.treesitter.is_in_node_range(node, pos[2] - 1, pos[3] - 1)
      end
    )

    vim.bo.textwidth = b and MAXW or tw
  end,
})

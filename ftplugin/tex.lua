if vim.fn.expand('%:e') == 'sty' then
  return
end

vim.o.spell = true

vim.api.nvim_buf_create_user_command(
  0,
  'AlignTable',
  'norm vie<leader>as&<CR>',
  {}
)

local id = nil
local function compile_on()
  return vim.api.nvim_create_autocmd('BufWritePre', {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      if
        not (
          vim.bo.modified
          and vim.g.loaded_vimtex
          and vim.g.vimtex_compiler_method == 'tectonic'
        )
      then
        return
      end

      vim.api.nvim_create_autocmd('BufWritePost', {
        once = true,
        buffer = vim.api.nvim_get_current_buf(),
        callback = function()
          vim.cmd('silent VimtexCompileSS')
        end,
      })
    end,
  })
end

vim.api.nvim_buf_create_user_command(0, 'AutoCompileOn', function()
  if id ~= nil then
    vim.notify('AutoCompile already active', vim.log.levels.INFO)
    return
  end

  id = compile_on()

  vim.api.nvim_buf_create_user_command(0, 'AutoCompileOff', function()
    vim.api.nvim_buf_del_user_command(0, 'AutoCompileOff')
    vim.api.nvim_del_autocmd(id)
    id = nil
  end, {})
end, {})

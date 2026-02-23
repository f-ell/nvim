local M = {}

-- NOTE: expressions containing whitespace are not supported
function M.expand_word()
  ---@type vim.lsp.Client
  local client = vim
    .iter(vim.lsp.get_clients({ bufnr = 0 }))
    :filter(
      ---@param c vim.lsp.Client
      function(c)
        return c.name == 'emmet_language_server'
      end
    )
    :nth(1)

  if client == nil then
    vim.notify('emmet-language-server is not running', vim.log.levels.ERROR)
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    position = vim.lsp.util.make_position_params(0, client.offset_encoding),
    abbreviation = L.str.word(true),
  }

  ---@diagnostic disable-next-line: param-type-mismatch
  local res, err = L.lsp:request(client, 'emmet/expandAbbreviation', params, 0)
  if err then
    L.lsp.notify_error(err)
    return
  end

  if res[1].result == '' then
    return
  end

  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local col_start, col_end =
    string.find(vim.api.nvim_get_current_line(), params.abbreviation) --[[@as integer]]

  vim.api.nvim_buf_set_text(
    0,
    lnum - 1,
    col_start - (vim.api.nvim_get_mode().mode == 'i' and 1 or 0),
    lnum - 1,
    col_end,
    { '' }
  )
  vim.api.nvim_put(
    vim.split(res[1].result --[[@as string]], '\n'),
    'c',
    false,
    true
  )
end

return M

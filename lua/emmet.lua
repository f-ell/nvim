local M = {}

-- NOTE: expressions containing whitespace are not supported
function M.expand_word()
  local emmetls = vim
    .iter(vim.lsp.get_clients({ bufnr = 0 }))
    :filter(function(
      client --[[@cast client vim.lsp.Client]]
    )
      return client.name == 'emmet_language_server'
    end)
    :next() --[[@as vim.lsp.Client]]

  if emmetls == nil then
    vim.notify('emmet-language-server is not running', vim.log.levels.ERROR)
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
    position = vim.lsp.util.make_position_params(0, emmetls.offset_encoding),
    abbreviation = L.str.word(true),
  }
  local err, res = L.lsp.request(emmetls, 'emmet/expandAbbreviation', params, 0)

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

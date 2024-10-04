local function load_uri(uri, res, client)
  if not res then
    return
  end

  local lines = vim.split(res.result, '\n')
  local bufnr = vim.uri_to_bufnr(uri)

  if vim.fn.bufloaded(bufnr) ~= 0 then
    return
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].buftype = 'nowrite'
  vim.bo[bufnr].bufhidden = 'hide'

  vim.lsp.buf_attach_client(bufnr, client.id)
end

local function uri2buf(uri, client)
  local params = { textDocument = { uri = uri } }
  local err, res = L.lsp.request(client, 'deno/virtualTextDocument', params, 0)

  if err then
    L.lsp.notify_error(err)
    return
  end

  load_uri(uri, res[1], client)
end

local denols_handler = function(err, result, ctx, _)
  if not result or L.tbl.is_empty(result) then
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  for _, res in pairs(result) do
    local uri = res.uri or res.targetUri
    if vim.startswith(uri, 'deno:') then
      uri2buf(uri, client)
    end
  end

  return { err = err, result = result }
end

return {
  root_dir = require('lspconfig').util.root_pattern('deno.json', 'deno.jsonc'),
  handlers = {
    -- main logic via neovim/nvim-lspconfig
    ['textDocument/definition'] = denols_handler,
    ['textDocument/typeDefinition'] = denols_handler,
    ['textDocument/references'] = denols_handler,
  },
}

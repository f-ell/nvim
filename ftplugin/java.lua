local function organizeImports()
  local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding) --[[@as table]]
  params.context =
    { diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 }) }

  local method = vim.lsp.protocol.Methods.textDocument_codeAction
  local err, res = L.lsp.request(
    vim.lsp.get_clients({ bufnr = 0, method = method }),
    method,
    params,
    0
  )
  if err then
    return
  end

  local req = vim
    .iter(res)
    :filter(function(
      r --[[@cast r EnrichedLspResponse]]
    )
      return r.result.kind == 'source.organizeImports'
    end)
    :nth(1) --[[@as EnrichedLspResponse]]
  if L.tbl.isempty(req) then
    return
  end

  err, res = L.lsp.request(
    client,
    vim.lsp.protocol.Methods.codeAction_resolve,
    req.result,
    0
  )
  if err then
    return
  end

  L.lsp.apply_edit(res[1])
end

vim.api.nvim_create_autocmd('BufWritePre', {
  buffer = vim.api.nvim_get_current_buf(),
  callback = function()
    if not vim.bo.modified then
      return
    end

    organizeImports()
  end,
})

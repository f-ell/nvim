vim.bo.expandtab = false

local function organizeImports()
  local client = vim.lsp.get_clients({ name = 'gopls' })[1]
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics(0) }

  local err, res = L.lsp.request(
    L.lsp.clients_by_method(vim.lsp.protocol.Methods.textDocument_codeAction),
    vim.lsp.protocol.Methods.textDocument_codeAction,
    params,
    0
  )
  if err then
    return
  end

  vim
    .iter(res)
    :filter(function(
      r --[[@cast r EnrichedLspResponse]]
    )
      return r.result.kind == 'source.organizeImports'
    end)
    :each(function(
      r --[[@cast r EnrichedLspResponse]]
    )
      L.lsp.apply_edit(r)
    end)
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

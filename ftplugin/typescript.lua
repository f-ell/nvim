local function organizeImports()
  local client = vim
    .iter(vim.lsp.get_clients())
    :filter(function(
      c --[[@cast c vim.lsp.Client]]
    )
      return c.name == 'vtsls' or c.name == 'denols'
    end)
    :nth(1)

  local diagnostics = vim
    .iter(vim.diagnostic.get(0, {
      namespace = vim.lsp.diagnostic.get_namespace(client.id),
    }))
    :map(function(d)
      return {
        range = {
          start = {
            line = d.lnum,
            character = d.col,
          },
          ['end'] = {
            line = d.end_lnum,
            character = d.end_col,
          },
        },
        severity = d.severity,
        message = d.message,
        source = d.source,
        code = d.code,
        data = d.user_data and (d.user_data.lsp or {}),
      }
    end)
    :totable()

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(0),
    range = {
      start = {
        line = 0,
        character = 0,
      },
      ['end'] = {
        line = vim.api.nvim_buf_line_count(0),
        character = 0,
      },
    },
    context = {
      only = { 'source.organizeImports' },
      diagnostics = diagnostics,
    },
  }

  local err, res = L.lsp.request(
    client,
    vim.lsp.protocol.Methods.textDocument_codeAction,
    params,
    0
  )
  if err or L.tbl.isempty(res) then
    return
  end

  err, res = L.lsp.request(
    client,
    vim.lsp.protocol.Methods.codeAction_resolve,
    res[1].result --[[@as lsp.TextDocumentPositionParams]],
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

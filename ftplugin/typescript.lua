---@param client vim.lsp.Client
local function organizeImports(client)
  ---@type lsp.Diagnostic[]
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
      } --[[@as lsp.Diagnostic]]
    end)
    :totable()

  ---@type lsp.CodeActionParams
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

  local res, err = L.lsp:request(
    client,
    vim.lsp.protocol.Methods.textDocument_codeAction,
    params,
    0
  )
  if err then
    L.lsp.notify_error(err)
    return
  end

  ---@type lsp.CodeAction
  local ca = vim
    .iter(res[1].result)
    :filter(
      ---This filters any returned commands, since those don't have a `kind`.
      ---@param ca lsp.CodeAction | lsp.Command
      function(ca)
        return ca.kind == 'source.organizeImports'
      end
    )
    :nth(1)

  if table.isempty(ca) then
    vim.notify(
      'Failed to organize imports: no suitable code action found.',
      vim.log.levels.WARN
    )
    return
  end

  res, err =
    L.lsp:request(client, vim.lsp.protocol.Methods.codeAction_resolve, ca, 0)
  if err then
    L.lsp.notify_error(err)
    return
  end

  -- Resolution request always returns a single code action.
  ca = res[1].result --[[@as lsp.CodeAction]]
  vim.lsp.util.apply_workspace_edit(ca.edit, client.offset_encoding)
  if ca.command then
    client:exec_cmd(ca.command)
  end
end

vim.api.nvim_create_autocmd('BufWritePre', {
  buffer = vim.api.nvim_get_current_buf(),
  callback = function()
    if not vim.bo.modified then
      return
    end

    local client = vim
      .iter(vim.lsp.get_clients())
      :filter(function(
        c --[[@cast c vim.lsp.Client]]
      )
        return c.name == 'vtsls' or c.name == 'denols'
      end)
      :nth(1)
    if not client then
      vim.notify('No server available for LSP hooks', vim.log.levels.WARN)
      return
    end

    organizeImports(client)
  end,
})

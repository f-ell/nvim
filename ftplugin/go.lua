vim.bo.expandtab = false

---@param client vim.lsp.Client
local function organize_imports(client)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding) --[[@as table]]
  params.context =
    { diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 }) }

  local method = vim.lsp.protocol.Methods.textDocument_codeAction
  local res, err = L.lsp:request(client, method, params, 0)
  if err then
    vim.notify('Failed to organize imports.', vim.log.levels.ERROR)
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

  vim.lsp.util.apply_workspace_edit(ca.edit, client.offset_encoding)
  if ca.command then
    client:exec_cmd(ca.command)
  end
end

---@param client vim.lsp.Client
local function regenerate_cgo(client)
  client:exec_cmd({
    title = 'Regenerate cgo',
    command = 'gopls.regenerate_cgo',
    arguments = { vim.lsp.util.make_text_document_params() },
  })
end

vim.api.nvim_create_autocmd('BufWritePre', {
  buffer = vim.api.nvim_get_current_buf(),
  callback = function()
    if not vim.bo.modified then
      return
    end

    local client = vim.lsp.get_clients({ name = 'gopls' })[1]
    if not client then
      vim.notify(
        'Failed to run hooks. No server available.',
        vim.log.levels.WARN
      )
      return
    end

    organize_imports(client)
    regenerate_cgo(client)
  end,
})

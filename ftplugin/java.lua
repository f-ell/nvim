---@param client vim.lsp.Client
local function organizeImports(client)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding) --[[@as table]]
  params.context =
    { diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 }) }

  local method = vim.lsp.protocol.Methods.textDocument_codeAction
  local res, err = L.lsp:request(client, method, params, 0)
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
  if not ca then
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

    local client = vim.lsp.get_clients({ name = 'jdtls' })[1]
    if not client then
      vim.notify('No server available for LSP hooks', vim.log.levels.WARN)
      return
    end

    organizeImports(client)
  end,
})

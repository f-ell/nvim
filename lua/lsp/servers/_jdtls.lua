local M = {}

-- TODO: support field picking
local function generateToStringPrompt(_, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)

  local err, res =
    L.lsp.request(client, 'java/checkToStringStatus', ctx.params, ctx.bufnr)

  if err then
    L.lsp.notify_error(err[1], vim.log.levels.ERROR)
    return
  end

  res = res[1]
  if res.result.exists then
    vim.notify(
      ('`toString()` already exists in `%s`'):format(res.result.type),
      vim.log.levels.INFO
    )
    return
  end

  _, res = L.lsp.request(
    client,
    'java/generateToString',
    { context = ctx.params, fields = res.result.fields },
    ctx.bufnr
  )
  vim.lsp.util.apply_workspace_edit(res[1].result, client.offset_encoding)
end

M.commands = {
  ['java.action.generateToStringPrompt'] = generateToStringPrompt,
}

return M

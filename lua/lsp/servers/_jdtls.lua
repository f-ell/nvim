local M = {}

-- TODO: support field picking
local function generateToStringPrompt(_, ctx)
  local client, res = vim.lsp.get_client_by_id(ctx.client_id), nil

  res =
    L.lsp.request(client, 'java/checkToStringStatus', ctx.params, ctx.bufnr)[1]

  if not res then
    return
  end

  if res.result.exists then
    vim.notify(
      ('`toString()` already exists in `%s`'):format(res.result.type),
      vim.log.levels.INFO
    )
    return
  end

  res = L.lsp.request(
    client,
    'java/generateToString',
    { context = ctx.params, fields = res.result.fields },
    ctx.bufnr
  )[1]
  vim.lsp.util.apply_workspace_edit(res.result, client.offset_encoding)
end

M.commands = {
  ['java.action.generateToStringPrompt'] = generateToStringPrompt,
}

return M

---@class (exact) lsp.ui.cda.CodeAction
---@field title string
---@field virt HlTuple[][] @Subsequent title lines to render as virtual text.
---@field virt_id number? @Extmark ID.
---@field client_id number
---@field client_name string
---@field action lsp.CodeAction

---@class lsp.ui.CodeAction
local M = {
  ---@package
  _util = {
    signs = vim.diagnostic.config().signs,
    ---@param item lsp.ui.cda.CodeAction
    format = function(item, _, _)
      return {
        item.title,
        -- stylua: ignore
        -- Show source only if there is no virtual text.
        #item.virt == 0 and { item.client_name, 'NonText' } or nil,
      }
    end,
  },
}

function M.codeaction()
  local params = vim.lsp.util.make_range_params(0, 'utf-8') --[[@as table]]
  params.context = {
    diagnostics = vim
      .iter(vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 }))
      :map(function(d)
        return vim.fn.values(d.user_data)
      end)
      :flatten()
      :totable(),
  }

  local method = vim.lsp.protocol.Methods.textDocument_codeAction
  local err, res = L.lsp.request(
    vim.lsp.get_clients({ bufnr = 0, method = method }),
    method,
    params,
    0
  )

  if err then
    L.lsp.notify_error(err)
    return
  elseif L.tbl.isempty(res) then
    vim.notify('No codeactions available', vim.log.levels.INFO)
    return
  end

  -- Ignore code action kind for deduplication. Primarily relevant for
  -- 'identical' code actions returned from both an LSP and a Linter.
  for i = 1, #res do
    res[i].result.kind = nil
  end

  M:_open(vim.fn.uniq(res) --[[ @as LspResponse[] ]])
end

---@package
---@param req LspResponse[]
---@return lsp.ui.cda.CodeAction[]
function M:_transform(req)
  local actions = {}

  for i, r in pairs(req) do
    local res = r.result --[[@as lsp.CodeAction]]
    -- NOTE: hanging carriage return when server returns '\r\n'-delimited lines.
    local it = vim.iter(vim.split(res.title, '\n', { trimempty = true }))

    local title = it:next()
    local virt = it:map(
      ---@param ln string
      function(ln)
        return { { (' '):rep(string.len(i) + 1) .. ln, 'Normal' } }
      end
    ):totable()
    if #virt > 0 then
      table.insert(virt[#virt], { ' ' .. r.name, 'NonText' })
    end

    table.insert(actions, {
      title = title,
      virt = virt,
      virt_id = nil,
      client_id = r.id,
      client_name = r.name,
      action = res,
    } --[[@as lsp.ui.cda.CodeAction]])
  end

  return actions
end

---@package
---@param items lsp.ui.cda.CodeAction[]
---@param winnr number
---@param bufnr number
---@param nsid number
function M:_set_highlights(items, winnr, bufnr, nsid)
  local height = vim.iter(items):fold(
    #items,
    ---@param c lsp.ui.cda.CodeAction
    function(acc, c)
      return acc + #c.virt
    end
  )

  for i, item in pairs(items) do
    item.virt_id = vim.api.nvim_buf_set_extmark(bufnr, nsid, i - 1, 0, {
      id = item.virt_id,
      virt_lines = item.virt,
    })
  end

  vim.api.nvim_win_set_height(winnr, height)
end

---@package
---@param c lsp.ui.cda.CodeAction
function M:_do_action(c)
  local ca = c.action

  if ca.edit then
    L.lsp.apply_edit({
      id = c.client_id,
      name = c.client_name,
      result = ca --[[@as RPCResult]],
    })
  elseif
    ca.action --[[@as fun()?]]
    and type(ca.action --[[@as fun()?]]) == 'function'
  then
    -- WARN: out of spec, which servers rely on this?
    vim.notify(
      'Executing out-of-spec function with field `action`.',
      vim.log.levels.WARN
    )

    ---@diagnostic disable-next-line: undefined-field
    ca.action()
  elseif ca.command then
    local cmd = type(ca.command) == 'table' and ca.command or ca
    local client = vim.lsp.get_client_by_id(c.client_id)

    assert(
      client
        and client:supports_method(
          vim.lsp.protocol.Methods.workspace_executeCommand
        ),
      'Client is missing `executeCommand` provider.'
    )

    if
      client.handlers
      ---Required for out-of-spec code actions with jdtls.
      ---@diagnostic disable-next-line
      and client.handlers['workspace/executeClientCommand']
      and vim.lsp.commands[cmd.command]
    then
      vim.lsp.commands[cmd.command](cmd, {
        method = vim.lsp.protocol.Methods.textDocument_codeAction,
        bufnr = 0,
        client_id = client.id,
        params = vim.lsp.util.make_range_params(0, client.offset_encoding),
      })
    elseif
      -- Command is available.
      vim.tbl_contains(
        client.server_capabilities.executeCommandProvider.commands,
        cmd.command
      )
    then
      L.lsp.request(client, vim.lsp.protocol.Methods.workspace_executeCommand, {
        command = cmd.command,
        arguments = cmd.arguments,
        --- FIX: field does not exist - does this work as intended?
        ---@diagnostic disable-next-line: undefined-field
        workDoneToken = cmd.workDoneToken,
      }, 0)
    else
      vim.notify(
        ('Command is not supported by client `%s`.'):format(cmd.command),
        vim.log.levels.ERROR
      )
    end
  else
    local err, resolved = L.lsp.request(
      { vim.lsp.get_client_by_id(c.client_id) },
      vim.lsp.protocol.Methods.codeAction_resolve,
      ca,
      0,
      -1
    )

    if err then
      L.lsp.notify_error(err)
      return
    end

    L.lsp.apply_edit(resolved[1])
  end
end

---@package
---@param req LspResponse[]
function M:_open(req)
  local actions = self:_transform(req)

  local c = L.ui.pick(actions, 'instant', self._util.format, {
    title = {
      {
        (' %s '):format(self._util.signs.text[vim.diagnostic.severity.INFO]),
        self._util.signs.numhl[vim.diagnostic.severity.INFO],
      },
      { 'Code Actions ', 'FloatTitle' },
    },
    zindex = 2,
    noautocmd = true,
  }, function(winnr, bufnr, nsid)
    return M:_set_highlights(actions, winnr, bufnr, nsid)
  end)[1]

  if c == nil then
    return
  end
  self:_do_action(c)
end

return M

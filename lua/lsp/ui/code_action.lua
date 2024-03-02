local L = require('lib')

---@class (exact) LspUiModuleCodeAction:LspUiModule
---@field codeaction fun()

---@type LspUiModuleCodeAction
---@diagnostic disable-next-line: missing-fields
local M = {}

M._util = {
  signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
    return vim.startswith(s.name, 'DiagnosticSign')
  end),
}

function M.codeaction()
  local params = vim.lsp.util.make_range_params()
  params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics(0) }

  local res = L.lsp.request(
    L.lsp.clients_by_cap('codeAction'),
    'textDocument/codeAction',
    params,
    0
  )

  if not L.tbl.is_empty(res) then
    M:_open(res)
  end
end

function M:_preprocess(raw)
  local tbl = {}

  for i = 1, #raw do
    tbl[i] = {
      msg = {},
      src = raw[i].name,
    }

    for ln in raw[i].result.title:gmatch('(.-)\r?\n') do
      table.insert(tbl[i].msg, ln)
    end
    -- WARN: unstable use of character class
    table.insert(tbl[i].msg, raw[i].result.title:match('[\r\n]*([^\r\n]*)$'))
  end

  for i = 1, #tbl do
    for j = 2, #tbl[i].msg do
      tbl[i].msg[j] = (' '):rep(string.len(i) + 1) .. tbl[i].msg[j]
    end
  end

  return tbl
end

function M:_format(proc)
  local tbl = {}

  for i = 1, #proc do
    local offset = #tbl + 1

    for j = 1, #proc[i].msg do
      table.insert(tbl, proc[i].msg[j])
    end

    tbl[offset] = i .. ' ' .. tbl[offset]
    tbl[#tbl] = tbl[#tbl] .. ' ' .. proc[i].src
  end

  return tbl
end

function M:_set_highlights(bufnr, proc)
  local offset = -1

  for i = 1, #proc do
    local len = string.len(i)

    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      self._util.signs[i % #self._util.signs ~= 0 and i % #self._util.signs or #self._util.signs].texthl,
      offset + i,
      0,
      len
    )
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      'NeutralFloat',
      offset + (#proc[i].msg > 1 and #proc[i].msg - 1 or 0) + i,
      (#proc[i].msg > 1 and 0 or len + 1) + proc[i].msg[#proc[i].msg]:len(),
      -1
    )

    if #proc[i].msg > 1 then
      offset = offset + #proc[i].msg - 1
    end
  end
end

function M:_register_float_actions(data)
  local do_action = function(num)
    L.win.close(data.nwin)

    local act = data.res[num]
    local res = act.result

    if res.edit then
      L.lsp.apply_edit(act)
    elseif res.action and type(res.action) == 'function' then
      res.action()
    elseif res.command then
      local cmd = type(res.command) == 'table' and res.command or act.result
      local client = vim.lsp.get_client_by_id(act.id)

      local provider = client.server_capabilities.executeCommandProvider
      if
        not provider
        or (
          type(provider) == 'table'
          and (
            L.tbl.is_empty(provider)
            or not vim.tbl_contains(provider.commands, cmd.command)
          )
        )
      then
        vim.notify("Client doesn't support command: '" .. cmd.command .. "'", 3)
        return
      end

      L.lsp.request({ client }, 'workspace/executeCommand', {
        command = cmd.command,
        arguments = cmd.arguments,
        workDoneToken = cmd.workDoneToken,
      }, 0)
    else
      local client = vim.lsp.get_client_by_id(act.id)
      local resolved =
        L.lsp.request({ client }, 'codeAction/resolve', res, 0)[1]

      if resolved then
        L.lsp.apply_edit(resolved)
      else
        vim.notify('Failed to resolve code-action.', 4)
      end
    end
  end

  L.key.nnmap('<C-c>', function()
    L.win.close(data.nwin)
  end, { buffer = true })

  L.key.nnmap('<CR>', function()
    local ln = vim.fn.line('.')
    local offset = 0

    -- PERF: suboptimal but good enough for any reasonable use-case
    for i = 1, #data.proc do
      for _ = 2, #data.proc[i].msg do
        table.insert(data.res, offset + i, data.res[offset + i])
        offset = offset + 1
      end

      if offset + i > ln then
        goto continue
      end
    end
    ::continue::

    do_action(ln)
  end, { buffer = true })

  for i = 1, #data.proc do
    L.key.nnmap(tostring(i), function()
      do_action(i)
    end, { buffer = true })
  end

  for _, lhs in pairs({ 'v', 'V', '<C-v>' }) do
    L.key.nnmap(lhs, '', { buffer = true })
  end

  L.cmd.event({ 'WinLeave', 'QuitPre' }, data.nbuf, function()
    L.win.close(data.nwin)
  end)
end

function M:_open(raw)
  local proc = self:_preprocess(raw)
  local content = self:_format(proc)

  local data = L.win.open_cursor(content, true, {
    title = {
      { ' ' .. self._util.signs[3].text, self._util.signs[3].texthl },
      { 'Code Actions ', 'FloatTitle' },
    },
    zindex = 2,
  })
  data.proc = proc
  data.res = raw

  self:_set_highlights(data.nbuf, proc)
  vim.api.nvim_win_set_cursor(data.nwin, { 1, 0 })
  self:_register_float_actions(data)
end

return M

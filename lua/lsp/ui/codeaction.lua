-- inspired by glepnir's Lspsaga: https://github.com/glepnir/lspsaga.nvim
local L = require('utils.lib')
local M = {}

-- TODO: diversify highlights
local highlights = {
  'HintFloatInv',
  'InfoFloatInv',
  'WarningFloatInv',
  'ErrorFloatInv'
}

local sev_sign = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
  return vim.startswith(s.name, 'DiagnosticSign')
end)


local preprocess = function(raw)
  local tbl = {}

  for idx, res in pairs(raw) do
    tbl[idx] = {
      msg = {},
      src = res.name
    }

    for ln in res.result.title:gmatch('(.-)\r?\n') do
      table.insert(tbl[idx].msg, ln)
    end
    -- WARN: unstable use of character class
    table.insert(tbl[idx].msg, res.result.title:match('[\r\n]*(.*)'))
  end

  return tbl
end


local format = function(proc)
  local tbl = {}

  for idx, action in pairs(proc) do
    local offset = #tbl + 1
    for i = 1, #action.msg do
      table.insert(tbl, action.msg[i])
    end
    tbl[offset] = ' '..idx..'  '..tbl[offset]
    tbl[#tbl] = tbl[#tbl]..' ('..action.src..')'
  end

  return tbl
end


-- FIX: verify this works with multiline codeactions
local set_highlights = function(bufnr, proc)
  vim.api.nvim_buf_add_highlight(bufnr, -1, 'InfoFloatSp', 0, 0, -1)
  vim.api.nvim_buf_add_highlight(bufnr, -1, 'NeutralFloat', 1, 0, -1)

  local offset = 0
  for i = 1, #proc do
    local len = 2 + string.len(i)

    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      highlights[i % #highlights ~= 0 and i % #highlights or 4],
      offset + i + 1,
      0,
      len
    )
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      'NeutralFloatSp',
      offset + (#proc[i].msg > 1 and #proc[i].msg or 0) + i + 1,
      len + #proc[i].msg[#proc[i].msg] + 1,
      -1
    )

    if #proc[i].msg > 1 then
      offset = offset + #proc[i].msg - 1
    end
  end
end


local register_float_actions = function(data)
  local do_action = function(num)
    L.win.close(data.nwin, data.owin, data.pos)

    local act = data.res[num]
    local res = act.result

    if res.edit then
      L.lsp.apply_edit(act)
    elseif res.action and type(res.action) == 'function' then
      res.action()
    elseif res.command then
      local cmd = type(res.command) == 'table' and res.command or act.result
      local client = vim.lsp.get_client_by_id(act.id)

      local prov = client.server_capabilities.executeCommandProvider
      if not prov or (type(prov) == 'table' and (L.tbl.is_empty(prov)
        or not vim.tbl_contains(prov.commands, cmd.command))) then
        vim.notify('Client doesn\'t support command: \''..cmd.command..'\'', 3)
        return
      end

      L.lsp.request({ client }, 'workspace/executeCommand', {
        command = cmd.command, arguments = cmd.arguments,
        workDoneToken = cmd.workDoneToken
      }, 0)
    else
      local client = vim.lsp.get_client_by_id(act.id)
      local resolved = L.lsp.request({ client }, 'codeAction/resolve', res, 0)[1]

      if resolved then
        L.lsp.apply_edit(resolved)
      else
        vim.notify('Failed to resolve code-action.', 4)
      end
    end
  end

  L.key.nnmap('<C-c>', function()
    L.win.close(data.nwin, data.owin, data.pos) end, { buffer = true })
  L.key.nnmap('<CR>', function()
    local num = vim.fn.line('.') - 2
    if num < 1 then return end
    do_action(num)
  end, { buffer = true })

  for i = 1, #data.proc do
    L.key.nnmap(tostring(i), function() do_action(i) end, { buffer = true })
  end

  for _, lhs in pairs({
    'h', 'l', 'w', 'W', 'b', 'B', 'e', 'E', 'f', 'F', 't', 'T', 'v', 'V',
    '<C-v>'
  }) do
    L.key.nnmap(lhs, '', { buffer = true })
  end

  L.cmd.event({ 'WinLeave', 'QuitPre' }, data.nbuf, function()
    L.win.close(data.nwin, data.owin, data.pos) end)
end


local open = function(raw)
  local proc = preprocess(raw)
  local content = format(proc)
  table.insert(content, 1, sev_sign[3].text..'Code Actions')
  table.insert(content, 2, L.win.separator(content))

  local data = L.win.open_cursor(content, false, true, { zindex = 2 })
  data.proc = proc
  data.res = raw

  set_highlights(data.nbuf, proc)
  vim.api.nvim_win_set_cursor(data.nwin, { 3, 0 })
  register_float_actions(data)
end

local try_action = function()
  local params = vim.lsp.util.make_range_params()
  params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics(0) }

  local res = L.lsp.request(L.lsp.clients_by_cap('codeAction'),
    'textDocument/codeAction', params, 0)
  if L.tbl.is_empty(res) then return end

  open(res)
end


M.codeaction = function() try_action() end
return M

local L = require('lib')
local M = {}

local signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
  return vim.startswith(s.name, 'DiagnosticSign')
end)

local preprocess = function(raw)
  local res = raw.res
  local tbl = { active = raw.active }

  local i0, i1
  local sig = res.result.signatures[1]

  -- stupid lsp spec. just send the darn location.
  if type(sig.parameters[1].label) == 'string' then
    i0 = ({ sig.label:find(sig.parameters[1].label) })[1] - 1
    i1 = ({ sig.label:find(sig.parameters[#sig.parameters].label) })[2] + 1
  else
    i0 = sig.parameters[1].label[1]
    i1 = sig.parameters[#sig.parameters].label[2] + 1
  end

  tbl.title = sig.label:sub(0, i0) .. '...' .. sig.label:sub(i1) .. ' '

  tbl.signature = (
    res.result.activeSignature and res.result.activeSignature or 0
  ) + 1
  tbl.parameter = (
    res.result.activeParameter and res.result.activeParameter
    or res.result.signatures[tbl.signature].activeParameter
  ) + 1

  for i = 1, #res.result.signatures do
    local s = res.result.signatures[i]
    tbl[i] = {
      sig = s.label,
      labels = {},
    }

    for j = 1, #s.parameters do
      if type(s.parameters[j].label) == 'string' then
        local pos = { s.label:find(s.parameters[j].label, 0, true) }
        table.insert(tbl[i].labels, { pos[1] - 1, pos[2] })
      else
        table.insert(tbl[i].labels, s.parameters[j].label)
      end
    end
  end

  return tbl
end

local format = function(proc)
  if proc.active then
    return {
      proc[proc.signature].sig:sub(
        proc[proc.signature].labels[1][1] + 1,
        proc[proc.signature].labels[#proc[proc.signature].labels][2]
      ),
    }
  end

  local tbl = {}

  for i = 1, #proc do
    table.insert(
      tbl,
      i
        .. ' '
        .. proc[i].sig:sub(
          proc[i].labels[1][1] + 1,
          proc[i].labels[#proc[i].labels][2]
        )
    )
  end

  return tbl
end

local set_highlights = function(bufnr, proc)
  if proc.active then
    local offset = proc[proc.signature].sig:len()
      - proc[proc.signature].sig
        :sub(proc[proc.signature].labels[1][1] + 1)
        :len()

    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      'Search',
      0,
      proc[proc.signature].labels[proc.parameter][1] - offset,
      proc[proc.signature].labels[proc.parameter][2] - offset
    )

    return
  end

  for i = 1, #proc do
    vim.api.nvim_buf_add_highlight(
      bufnr,
      -1,
      signs[i % #signs ~= 0 and i % #signs or #signs].texthl,
      i - 1,
      0,
      string.len(i)
    )
  end
end

local open = function(raw)
  local proc = preprocess(raw)
  local content = format(proc)

  local data = L.win.open_cursor(content, false, {
    title = {
      { ' ' .. signs[3].text, signs[3].texthl },
      { 'Signature ', 'FloatTitle' },
      { proc.title, 'NeutralFloat' },
    },
    zindex = 2,
  })

  set_highlights(data.nbuf, proc)

  L.cmd.event(
    { 'BufLeave', 'CursorMoved', 'InsertLeave', 'TextChangedI', 'WinNew' },
    data.obuf,
    function()
      L.win.close(data.nwin)
    end
  )
end

local try_signature_help = function(active)
  local params = vim.lsp.util.make_position_params()

  local res = L.lsp.request(
    L.lsp.clients_by_cap('signatureHelp'),
    'textDocument/signatureHelp',
    params,
    0
  )[1]

  if not L.tbl.is_empty(res) then
    if L.tbl.is_empty(res.result.signatures) then
      vim.notify('No signature help available.', 3)
      return
    end

    open({ res = res, active = active })
  end
end

M.active = function()
  try_signature_help(true)
end
M.available = function()
  try_signature_help(false)
end
return M

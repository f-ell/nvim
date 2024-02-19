local L = require('lib')
local M = {}

local signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
  return vim.startswith(s.name, 'DiagnosticSign')
end)

local preprocess = function(raw)
  local tbl = {}
  tbl.signature = (
    raw.result.activeSignature and raw.result.activeSignature or 0
  ) + 1
  tbl.parameter = (
    raw.result.activeParameter and raw.result.activeParameter
    or raw.result.signatures[tbl.signature].activeParameter
  ) + 1

  for i = 1, #raw.result.signatures do
    local s = raw.result.signatures[i]
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
  return {
    proc[proc.signature].sig:sub(
      proc[proc.signature].labels[1][1] + 1,
      proc[proc.signature].labels[#proc[proc.signature].labels][2]
    ),
  }
end

local set_highlights = function(bufnr, proc)
  local offset = proc[proc.signature].sig:len()
    - proc[proc.signature].sig:sub(proc[proc.signature].labels[1][1] + 1):len()

  vim.api.nvim_buf_add_highlight(
    bufnr,
    -1,
    'Search',
    0,
    proc[proc.signature].labels[proc.parameter][1] - offset,
    proc[proc.signature].labels[proc.parameter][2] - offset
  )
end

local open = function(raw)
  local proc = preprocess(raw)
  local content = format(proc)

  local data = L.win.open_cursor(content, false, {
    title = {
      { ' ' .. signs[3].text, signs[3].texthl },
      { 'Signature ', 'FloatTitle' },
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

local try_signature_help = function()
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

    open(res)
  end
end

M.signature_help = function()
  try_signature_help()
end
return M

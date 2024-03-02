local L = require('lib')

---@class (exact) LspUiModuleSignatureHelp:LspUiModule
---@field active fun()
---@field available fun()

---@type LspUiModuleSignatureHelp
---@diagnostic disable-next-line: missing-fields
local M = {}

M._util = {
  signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
    return vim.startswith(s.name, 'DiagnosticSign')
  end),
}

M.active = function()
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

    M:_open({ res = res, active = true })
  end
end

M.available = function()
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

    M:_open({ res = res, active = false })
  end
end

function M:_preprocess(raw)
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

function M:_format(proc)
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

function M:_set_highlights(bufnr, proc)
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
      self._util.signs[i % #self._util.signs ~= 0 and i % #self._util.signs or #self._util.signs].texthl,
      i - 1,
      0,
      string.len(i)
    )
  end
end

function M:_open(raw)
  local proc = self:_preprocess(raw)
  local content = self:_format(proc)

  local data = L.win.open_cursor(content, false, {
    title = {
      { ' ' .. self._util.signs[3].text, self._util.signs[3].texthl },
      { 'Signature ', 'FloatTitle' },
      { proc.title, 'NeutralFloat' },
    },
    zindex = 2,
  })

  self:_set_highlights(data.nbuf, proc)

  L.cmd.event(
    { 'BufLeave', 'CursorMoved', 'InsertLeave', 'TextChangedI', 'WinNew' },
    data.obuf,
    function()
      L.win.close(data.nwin)
    end
  )
end

return M

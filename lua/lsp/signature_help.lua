---@class lsp.ui.SignatureHelp : lsp.ui
local M = {}

M._util = {
  signs = vim.diagnostic.config().signs,
}

M.active = function()
  local method = vim.lsp.protocol.Methods.textDocument_signatureHelp
  local err, res = L.lsp.request(
    vim.lsp.get_clients({ bufnr = 0, method = method }),
    method,
    vim.lsp.util.make_position_params(0, 'utf-8'),
    0
  )

  if err then
    L.lsp.notify_error(err)
    return
  end
  if table.isempty(res[1]) or table.isempty(res[1].result.signatures) then
    vim.notify('No signature help available', vim.log.levels.INFO)
    return
  end
  if table.isempty(res[1].result.signatures[1].parameters) then
    vim.notify('Function takes no arguments', vim.log.levels.INFO)
    return
  end

  M:_open({ res = res, active = true })
end

M.available = function()
  local method = vim.lsp.protocol.Methods.textDocument_signatureHelp
  local err, res = L.lsp.request(
    vim.lsp.get_clients({ bufnr = 0, method = method }),
    method,
    vim.lsp.util.make_position_params(0, 'utf-8'),
    0
  )

  if err then
    L.lsp.notify_error(err)
    return
  end
  if table.isempty(res[1]) or table.isempty(res[1].result.signatures) then
    vim.notify('No signature help available', vim.log.levels.INFO)
    return
  end
  if table.isempty(res[1].result.signatures[1].parameters) then
    vim.notify('Function takes no arguments', vim.log.levels.INFO)
    return
  end

  M:_open({ res = res, active = false })
end

function M:_preprocess(raw)
  local res = raw.res[1]
  local tbl = { active = raw.active }

  local i0, i1
  local sig = res.result.signatures[1]

  -- stupid lsp spec. just send the darn location.
  if type(sig.parameters[1].label) == 'string' then
    i0 = ({ sig.label:find(sig.parameters[1].label, 0, true) })[1] - 1
    i1 = sig.label:len()
      - ({
        sig.label
          :reverse()
          :find(sig.parameters[#sig.parameters].label:reverse(), 0, true),
      })[1]
      + 2
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
    or 0
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
  local ns_id = vim.api.nvim_create_namespace('lsp-ui')

  if proc.active then
    local offset = proc[proc.signature].sig:len()
      - proc[proc.signature].sig
        :sub(proc[proc.signature].labels[1][1] + 1)
        :len()

    if proc.parameter <= #proc[proc.signature].labels then
      vim.hl.range(
        bufnr,
        ns_id,
        'Search',
        { 0, proc[proc.signature].labels[proc.parameter][1] - offset },
        { 0, proc[proc.signature].labels[proc.parameter][2] - offset }
      )
    end

    return
  end

  for i = 1, #proc do
    vim.hl.range(
      bufnr,
      ns_id,
      self._util.signs.numhl[i % #self._util.signs.text ~= 0 and i % #self._util.signs.text or #self._util.signs.text],
      { i - 1, 0 },
      { i - 1, string.len(i) }
    )
  end
end

function M:_open(raw)
  local proc = self:_preprocess(raw)
  local content = self:_format(proc)

  local data = L.win.open_cursor(content, false, {
    title = {
      {
        (' %s '):format(self._util.signs.text[vim.diagnostic.severity.INFO]),
        self._util.signs.numhl[vim.diagnostic.severity.INFO],
      },
      { 'Signature ', 'FloatTitle' },
      { proc.title, 'NeutralFloat' },
    },
    zindex = 2,
    noautocmd = true,
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

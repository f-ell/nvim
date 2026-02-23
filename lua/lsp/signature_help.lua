---@class (exact) lsp.ui.sig.Request
---@field active_only boolean
---@field responses lib.lsp.Response[]
---
---@class (exact) lsp.ui.sig.Signature
---@field active_param number? @Active parameter as defined by the signature itself.
---@field label string
---@field short_label string @Shortened signature label with all parameters removed.
---@field display string @List of all parameter names.
---@field params [number, number][] @Start-inclusive, end-exclusive indices in the signature's label for each parameter.
---
---@class (exact) lsp.ui.sig.SignatureHelp
---@field active_sig number
---@field active_param number? @Active parameter as defined by `lsp.SignatureHelp`.
---@field signatures lsp.ui.sig.Signature[]

---@class lsp.ui.SignatureHelp
local M = {
  ---@package
  _util = {
    signs = vim.diagnostic.config().signs,
    ---@type number
    win = nil,
  },
}

function M.active()
  M:_sig(true)
end

function M.available()
  M:_sig(false)
end

---@package
---@param active_only boolean
function M:_sig(active_only)
  local method = vim.lsp.protocol.Methods.textDocument_signatureHelp
  local clients = vim.lsp.get_clients({ bufnr = 0, method = method })

  local res, err = L.lsp:request(
    clients,
    method,
    vim.lsp.util.make_position_params(0, 'utf-8'),
    0
  )
  if err then
    L.lsp.notify_error(err)
    return
  end

  if table.isempty(res) then
    vim.notify('No signature help available', vim.log.levels.INFO)
    return
  end

  local s = res[1].result --[[@as lsp.SignatureHelp]]
  if table.isempty(s.signatures) then
    vim.notify('No signatures available', vim.log.levels.INFO)
    return
  end

  if table.isempty(s.signatures[1].parameters) then
    vim.notify('Function does not take any arguments', vim.log.levels.INFO)
    return
  end

  M:_open({ active_only = active_only, responses = res })
end

---@package
---@param si lsp.SignatureInformation
---@return lsp.ui.sig.Signature
function M:_map_siginfo(si)
  local i = 1

  ---@type [number, number][]
  local params = vim
    .iter(si.parameters)
    :map(
      ---@param pi lsp.ParameterInformation
      function(pi)
        local l = pi.label

        if type(l) == 'table' then
          return { l[1], l[2] }
        end

        -- Determine the position, at which the parameter occurs in the
        -- signature's label.
        local start, end_ = si.label:find(l, i, true)
        assert(
          start and end_,
          ('invalid signature: parameter `%s` not found in label `%s`'):format(
            l,
            si.label
          )
        )

        i = end_ + 1
        -- `string.find` returns 1-based, end-inclusive range. Those values are
        -- transformed to a 0-based, end-exclusive tuple.
        return { start - 1, end_ }
      end
    )
    :totable()

  -- Omit any contained parameters in the display label.
  local short_label = ('%s ... %s'):format(
    si.label:sub(1, params[1][1]),
    si.label:sub(params[#params][2] + 1)
  )
  -- Trim any leading function keywords.
  for _, kw in pairs({ 'fn', 'fun', 'function' }) do
    local _, end_ = short_label:find(('^%s '):format(kw))
    if end_ then
      short_label = short_label:sub(end_ + 1)
      break
    end
  end

  return {
    active_param = si.activeParameter,
    label = si.label,
    short_label = short_label,
    display = si.label:sub(params[1][1] + 1, params[#params][2]),
    params = params,
  } --[[@as lsp.ui.sig.Signature]]
end

---@package
---@param req lsp.ui.sig.Request
---@return lsp.ui.sig.SignatureHelp
function M:_transform(req)
  ---@type lsp.ui.sig.SignatureHelp[]
  local responses = {}

  for _, res in pairs(req.responses) do
    local r = res.result --[[@as lsp.SignatureHelp]]

    ---@type lsp.ui.sig.SignatureHelp
    local sh = {
      active_sig = r.activeSignature and r.activeSignature + 1 or 1,
      active_param = r.activeParameter and r.activeParameter + 1 or nil,
      signatures = vim
        .iter(r.signatures)
        :map(
          ---@param si lsp.SignatureInformation
          function(si)
            return self:_map_siginfo(si)
          end
        )
        :totable(),
    }

    -- Active parameter defined by the signature itself overrides the active
    -- parameter information provided by `lsp.SignatureHelp`.
    local p = sh.signatures[sh.active_sig].active_param
    if p then
      sh.active_param = p and p + 1 or nil
    end

    table.insert(responses, sh)
  end

  -- Prevent display of incorrect signature in cases where multiple servers
  -- returned different result-sets.
  local c, as, ap =
    #responses[1].signatures, responses[1].active_sig, responses[1].active_param
  assert(
    vim.iter(responses):all(
      ---@param sh lsp.ui.sig.SignatureHelp
      function(sh)
        return #sh.signatures == c
          and sh.active_sig == as
          and sh.active_param == ap
      end
    ),
    'failed to resolve active signature from mismatched responses'
  )

  -- Assume that all clients returned the same signatures.
  return responses[1]
end

---@package
---@param bufnr number
---@param active_only boolean
---@param sh lsp.ui.sig.SignatureHelp
function M:_set_highlights(bufnr, active_only, sh)
  if not sh.active_param then
    return
  end

  local nsid = vim.api.nvim_create_namespace('lsp-ui')
  vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)

  local p = sh.signatures[sh.active_sig].params[sh.active_param]
  -- Cursor is outside of valid range.
  if not p then
    return
  end

  -- Highlight offset based on stripped label and signature index.
  local offset = -sh.signatures[sh.active_sig].params[1][1]
    + (active_only and 0 or (string.len(sh.active_sig) + 1))

  vim.hl.range(
    bufnr,
    nsid,
    'Search',
    { sh.active_sig - 1, p[1] + offset },
    { sh.active_sig - 1, p[2] + offset }
  )
end

---@package
---@param req lsp.ui.sig.Request
function M:_open(req)
  -- Close any existing signature help windows. Stored window ID is overwritten
  -- with the newly opened window's.
  if self._util.win then
    L.win:close(self._util.win)
  end

  local sh = self:_transform(req)

  local content = req.active_only and { sh.signatures[sh.active_sig].display }
    or L.win.enumerate(vim
      .iter(sh.signatures)
      :map(
        ---@param s lsp.ui.sig.Signature
        function(s)
          return s.display
        end
      )
      :totable())

  local data = L.win:open_cursor(content, false, {
    title = {
      {
        (' %s '):format(self._util.signs.text[vim.diagnostic.severity.INFO]),
        self._util.signs.numhl[vim.diagnostic.severity.INFO],
      },
      { 'Signature ', 'FloatTitle' },
      { sh.signatures[sh.active_sig].short_label, 'NonText' },
      { ' ', 'Normal' },
    },
    focusable = false,
    zindex = 2,
    noautocmd = true,
  })
  self._util.win = data.nwin

  self:_set_highlights(data.nbuf, req.active_only, sh)

  L.cmd.register(
    { 'BufLeave', 'CursorMoved', 'InsertLeave', 'TextChangedI', 'WinNew' },
    data.obuf,
    function()
      L.win:close(data.nwin)
      self._util.win = nil
    end
  )
end

return M

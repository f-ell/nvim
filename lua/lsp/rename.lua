---@class (exact) lsp.ui.ren.Request
---@field references lib.lsp.Response[]
---@field definition lib.lsp.Response[]
---@field uri string @File URI for the active buffer.
---@field cursor [number, number] @Original cursor position.
---
---@class (exact) lsp.ui.ren.Rename
---@field references lsp.Location[]
---@field symbol string @Symbol being renamed.
---@field uri string @File URI for the active buffer.
---@field cursor [number, number] @Original cursor position.

---@class lsp.ui.Rename
local M = {
  ---@package
  _util = {
    signs = vim.diagnostic.config().signs,
    nsid = vim.api.nvim_create_namespace('lsp-ui'),
  },
}

function M.rename()
  local m_ref = vim.lsp.protocol.Methods.textDocument_references
  local clients = vim.lsp.get_clients({ bufnr = 0, method = m_ref })

  if table.isempty(clients) then
    vim.notify('No client with reference provider found.', vim.log.levels.INFO)
    return
  end

  local p_ref = vim.lsp.util.make_position_params(0, 'utf-8') --[[@as lsp.ReferenceParams]]
  p_ref.context = { includeDeclaration = true }

  local e_ref, r_ref = L.lsp:request(clients, m_ref, p_ref, 0)
  if e_ref then
    L.lsp.notify_error(e_ref)
    return
  end
  if table.isempty(r_ref) then
    vim.notify('No references found', vim.log.levels.INFO)
    return
  end

  local m_def = vim.lsp.protocol.Methods.textDocument_definition
  local p_def = vim.lsp.util.make_position_params(0, 'utf-8') --[[@as lsp.DefinitionParams]]

  local e_def, r_def = L.lsp:request(clients, m_def, p_def, 0)
  if e_def then
    L.lsp.notify_error(e_def)
    return
  end
  if table.isempty(r_def) then
    vim.notify('No definition found', vim.log.levels.WARN)
    return
  end

  M:_open({
    references = r_ref,
    definition = r_def,
    cursor = vim.api.nvim_win_get_cursor(0),
    uri = 'file://' .. vim.fn.expand('%:p'),
  })
end

---@package
---@param req lsp.ui.ren.Request
---@return lsp.ui.ren.Rename
function M:_transform(req)
  ---@type lsp.Location[]
  local def = vim
    .iter(req.definition)
    :map(
      ---@param res lib.lsp.Response
      ---@return lsp.Location[]
      function(res)
        local r = res.result --[[@as lsp.Definition]]
        return type(r[1]) == 'table' and r or { r }
      end
    )
    :flatten(1)
    :totable()

  -- Prevent incorrect rename in cases where multiple servers return different
  -- definitions for the active symbol.
  local uri, range = def[1].uri, def[1].range
  assert(
    vim.iter(def):all(
      ---@param l lsp.Location
      function(l)
        return l.uri == uri and vim.deep_equal(l.range, range)
      end
    ),
    'failed to resolve definition from mismatched responses'
  )

  ---The reference list may contain duplicate locations when multiple servers
  ---are queried for references. This does not matter so long as all highlights
  ---are later created in a single namespace that is always fully wiped.
  ---
  ---@type lsp.Location[]
  local refs = vim
    .iter(req.references)
    :map(
      ---@param res lib.lsp.Response
      ---@return lsp.Location
      function(res)
        return res.result
      end
    )
    :totable()

  local bufnr = vim.uri_to_bufnr(def[1].uri)
  local symbol = vim.api.nvim_buf_get_text(
    bufnr,
    def[1].range.start.line,
    def[1].range.start.character,
    def[1].range['end'].line,
    def[1].range['end'].character,
    {}
  )[1]

  return {
    references = refs,
    symbol = symbol,
    uri = req.uri,
    -- Correct column offset for later use with `nvim_win_set_cursor`
    cursor = { req.cursor[1], req.cursor[2] + 1 },
  } --[[@as lsp.ui.ren.Rename]]
end

---@package
---@param bufnr number
---@param ren lsp.ui.ren.Rename
function M:_set_highlights(bufnr, ren)
  ---Apply highlights only to references in the current buffer.
  ---@type lsp.Range[]
  local refs = vim
    .iter(ren.references)
    :filter(
      ---@param r lsp.Location
      function(r)
        return r.uri == ren.uri
      end
    )
    :map(
      ---@param r lsp.Location
      ---@return lsp.Range
      function(r)
        return r.range
      end
    )
    :totable()

  for _, r in pairs(refs) do
    vim.hl.range(
      bufnr,
      self._util.nsid,
      'Search',
      { r.start.line, r.start.character },
      { r['end'].line, r['end'].character }
    )
  end
end

---@package
---@param data lib.win.Data
---@param symbol string @Symbol being renamed.
---@param cursor [number, number] @Original cursor position.
---@param max number @Maximum window width in screen cells.
function M:_register_float_actions(data, symbol, cursor, min, max)
  local close = function()
    if vim.api.nvim_win_is_valid(data.nwin) then
      vim.api.nvim_win_close(data.nwin, true)
      vim.api.nvim_buf_clear_namespace(data.obuf, self._util.nsid, 0, -1)
      vim.api.nvim_win_set_cursor(data.owin, cursor)
    end
  end

  vim.bo[data.nbuf].modifiable = true
  vim.bo[data.nbuf].buftype = 'prompt'

  vim.fn.prompt_setprompt(data.nbuf, '')
  vim.fn.prompt_setinterrupt(data.nbuf, close)
  vim.fn.prompt_setcallback(data.nbuf, function(txt)
    txt = vim.trim(txt)
    if #txt == 0 then
      return
    end

    close()
    if txt == symbol then
      return
    end

    vim.lsp.buf.rename(txt, {})
  end)

  L.cmd.register({ 'WinLeave', 'QuitPre' }, data.nbuf, close)

  local maxlen = math.max(symbol:len(), min)
  L.cmd.register({ 'TextChanged', 'TextChangedI' }, data.nbuf, function()
    local len = vim.api.nvim_get_current_line():len()

    if len > maxlen and len < max then
      maxlen = len
      data.width = len + 1 -- Additional screen column to make room for cursor.
      vim.api.nvim_win_set_width(data.nwin, data.width)
    end
  end)
end

---@package
---@param req lsp.ui.ren.Request
function M:_open(req)
  local ren = self:_transform(req)

  local len = ren.symbol:len()
  local min = math.min(vim.o.columns, 24)
  local max = math.min(vim.o.columns, 48)

  local data = L.win:open_cursor({ ren.symbol }, true, {
    title = {
      {
        (' %s '):format(self._util.signs.text[vim.diagnostic.severity.INFO]),
        self._util.signs.numhl[vim.diagnostic.severity.INFO],
      },
      { 'Rename ', 'FloatTitle' },
    },
    zindex = 2,
    col = -1,
    width = math.min(math.max(len + 1, min), max),
    noautocmd = true,
  })

  self:_set_highlights(data.obuf, ren)
  self:_register_float_actions(data, ren.symbol, ren.cursor, min, max)
  vim.cmd('startinsert!')
end

return M

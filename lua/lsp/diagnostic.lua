---@alias lsp.ui.dgn.Type 'dir'|'line'
---
---@class (exact) lsp.ui.dgn.Request
---@field type lsp.ui.dgn.Type
---@field dgn vim.Diagnostic[]
---
---@class (exct) lsp.ui.dgn.Diagnostic
---@field head HlTuple
---@field virt HlTuple[][] @Subsequent message lines to render as virtual text.
---@field virt_id number? @Extmark ID.
---@field sev vim.diagnostic.Severity
---@field lnum number
---@field col number
---
---@class (exact) lsp.ui.dgn.Data
---@field type lsp.ui.dgn.Type
---@field title_icon HlTuple
---@field title_loc HlTuple
---@field dgn lsp.ui.dgn.Diagnostic[]

---@class lsp.ui.Diagnostic
local M = {
  ---@package
  _util = {
    signs = vim.diagnostic.config().signs,
    ---@type number
    win = nil,
  },
}

function M.get_next()
  M:_get_dir(vim.diagnostic.get_next())
end

function M.get_prev()
  M:_get_dir(vim.diagnostic.get_prev())
end

function M.get_line()
  local pos = vim.fn.getcurpos()
  local dgn = vim.diagnostic.get(0, { lnum = pos[2] - 1 })
  if #dgn == 0 then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end

  M:_open({ type = 'line', dgn = dgn })
end

---@package
---@param dgn vim.Diagnostic?
function M:_get_dir(dgn)
  if not dgn then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end

  local pos = { dgn.lnum, dgn.col }
  -- Get all diagnostics at the starting position.
  dgn = vim
    .iter(vim.diagnostic.get(0, { lnum = pos[1] }))
    :filter(function(d)
      return d.col == pos[2]
    end)
    :totable()

  if #dgn == 0 then
    vim.notify('No diagnostics found', vim.log.levels.INFO)
    return
  end

  M:_open({ type = 'dir', dgn = dgn })
end

---@param req lsp.ui.dgn.Request
---@return lsp.ui.dgn.Data
function M:_transform(req)
  ---@type lsp.ui.dgn.Diagnostic[]
  local dgn = {}

  for _, r in pairs(req.dgn) do
    -- Split produces hanging CR when the server returns '\r\n'-delimited lines.
    local it = vim.iter(vim.split(r.message, '\n', { trimempty = true }))

    -- Some language servers, e.g. ZLS, may sometimes return nil-diagnostics
    -- amidst others. We map those to empty strings to prevent an implicit
    -- conversion of tuples to an array (i.e. `{ [n] = 'hl-group' }`).
    --
    -- Order is important; `it:next()` may return a falsy value, which we want
    -- to keep intact.
    local head = {
      it:peek() == nil and '' or it:next(),
      self._util.signs.numhl[r.severity],
    }
    local virt = it:map(
      ---@param ln string
      function(ln)
        return L.str:wrap(ln, math.floor(vim.o.columns * 0.7))
      end
    )
      :flatten(1)
      :map(
        ---@param ln string
        function(ln)
          return {
            {
              (' '):rep(string.len(vim.o.showbreak)) .. ln,
              self._util.signs.numhl[r.severity],
            },
          }
        end
      )
      :totable()

    ---@type lsp.ui.dgn.Diagnostic
    local d = {
      head = head,
      virt = virt,
      sev = r.severity,
      lnum = r.lnum + 1,
      col = r.col + 1,
    }

    table.insert(dgn, d)
  end

  ---Maximum diagnostic severity (i.e. minimum value) present.
  ---@type vim.diagnostic.Severity
  local sev = vim
    .iter(dgn)
    :map(
      ---@param d lsp.ui.dgn.Diagnostic
      function(d)
        return d.sev
      end
    )
    :fold(math.huge, function(min, i)
      if i < min then
        min = i
      end
      return min
    end)

  ---@type lsp.ui.dgn.Data
  local data = {
    type = req.type,
    title_icon = {
      (' %s '):format(self._util.signs.text[sev]),
      self._util.signs.numhl[sev],
    },
    title_loc = {
      ('l.%d:%d '):format(dgn[1].lnum, dgn[1].col),
      'NeutralFloat',
    },
    dgn = dgn,
  }

  return data
end

---@package
---@param winnr number
---@param bufnr number
---@param dgn lsp.ui.dgn.Diagnostic[]
function M:_set_highlights(winnr, bufnr, dgn)
  local nsid = vim.api.nvim_create_namespace('lsp-ui')
  vim.api.nvim_buf_clear_namespace(bufnr, nsid, 0, -1)

  local vh = vim.iter(dgn):fold(
    0,
    ---@param d lsp.ui.dgn.Diagnostic
    function(acc, d)
      return acc + #d.virt
    end
  )

  for i, d in pairs(dgn) do
    d.virt_id = vim.api.nvim_buf_set_extmark(bufnr, nsid, i - 1, 0, {
      id = d.virt_id,
      virt_lines = d.virt,
    })
  end

  vim.api.nvim_win_set_height(
    winnr,
    vim.api.nvim_win_get_config(winnr).height + vh
  )
end

---@package
---@param req lsp.ui.dgn.Request
function M:_open(req)
  -- Close any existing diagnostic windows. Stored window ID is overwritten with
  -- the newly opened window's.
  if self._util.win then
    L.win:close(self._util.win)
  end

  local data = self:_transform(req)

  local content = vim
    .iter(data.dgn)
    :map(function(d)
      return { d.head }
    end)
    :totable()

  local lines = vim
    .iter(data.dgn)
    :map(
      ---@param d lsp.ui.dgn.Diagnostic
      function(d)
        return {
          { d.head[1] },
          vim
            .iter(d.virt)
            :flatten(1)
            :map(function(v)
              return v[1]
            end)
            :totable(),
        }
      end
    )
    :flatten(2)
    :totable()

  -- Jump to diagnotic location, adding the current position to the jumplist.
  if data.type == 'dir' then
    vim.cmd.mark('`')
    vim.fn.cursor({ data.dgn[1].lnum, data.dgn[1].col })
  end

  local win_data = L.win:open_cursor(content, false, {
    title = {
      data.title_icon,
      { 'Diagnostics ', 'FloatTitle' },
      data.title_loc,
    },
    focusable = false,
    zindex = 2,
    width = math.max(
      L.tbl.max_len(lines),
      data.title_icon[1]:len()
        + ('Diagnostics '):len()
        + data.title_loc[1]:len()
    ),
    noautocmd = true,
  })
  self._util.win = win_data.nwin

  self:_set_highlights(win_data.nwin, win_data.nbuf, data.dgn)

  -- TODO: on WinScrolled: move window to new cursor position instead.
  L.cmd.register(
    { 'BufLeave', 'CursorMoved', 'InsertEnter', 'WinScrolled' },
    win_data.obuf,
    function()
      L.win:close(win_data.nwin)
      self._util.win = nil
    end
  )
end

return M

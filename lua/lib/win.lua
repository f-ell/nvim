---@alias lib.win.ContentLn table<string|HlTuple>
---@alias lib.win.Content number|string[]|lib.win.ContentLn[]

---@class (exact) lib.win.Data
---@field obuf number @Buffer number of previously active buffer.
---@field owin number @Window number of previously active window.
---@field nbuf number @Buffer number of newly opened buffer.
---@field nwin number @Window number of newly opened window.
---@field config vim.api.keyset.win_config

---@class lib.Win
local Win = {
  ---Namespace ID used to apply highlighting to buffer contents.
  nsid = vim.api.nvim_create_namespace('lib.win'),
  ---@package
  _tbl = require('lib.tbl'),
}

---Desired horizontal padding for floating windows.
local _HPAD = 2
---Desired vertical padding for floating windows.
local _VPAD = 2

---Extract window title string from `nvim_open_win()`'s `config` table.
---
---@param config vim.api.keyset.win_config?
---@return string
function Win.parse_title(config)
  if not (config and config.title) then
    return ''
  end

  if type(config.title) == 'string' then
    return config.title
  end

  return vim
    .iter(config.title)
    :map(function(t)
      return t[1]
    end)
    :join('')
end

---Calculate maximum window width, maintaining desired padding.
---
---@return integer
function Win.max_width()
  return vim.o.columns - _HPAD
end

---Calculate maximum window height, maintaining desired padding.
---
---@return integer
function Win.max_height()
  return vim.o.lines - _VPAD
end

---@package
---Calculate window width.
---
---@param data number|string[] @Buffer number or buffer contents.
---@return integer
function Win:_width(data)
  if type(data) == 'number' then
    return self.max_width()
  end

  local len = self._tbl.max_len(data)
  return math.min(len > 0 and len or 1, self.max_width())
end

---@package
---Calculate window height, respecting wrapped lines and `showbreak`-offset.
---
---@param data number|string[] @Buffer number or buffer contents.
---@return integer
function Win:_height(data)
  if type(data) == 'number' then
    return self.max_height()
  end

  -- FIX: width needs to account for fold-/sign-/status-/numbercolumn
  local w = vim.o.columns - _HPAD
  local sb = vim.fn.strdisplaywidth(vim.o.showbreak)

  local c = vim
    .iter(data)
    :map(vim.fn.strdisplaywidth)
    :map(function(len)
      if len == w then
        return 0
      end

      local wrap = len / w
      -- This causes FP rounding issues when a wrap fills an entire screen line.
      -- Subtract 10e-15 to prevent `wrap + inc` from adding to a whole number.
      local wrap_inc = (math.floor(wrap) * sb / w) - math.pow(10, -15)
      return math.floor(wrap + wrap_inc)
    end)
    :fold(0, function(acc, v)
      return acc + v
    end)

  return math.min(math.max(#data + c, 1), self.max_height())
end

---@package
---Calculate appropriate window anchor and required offset for centering the
---window, based on the current cursor position.
---
---@return 'NW'|'SW' anchor, 0|1 offset
function Win._anchor_offset()
  local anchor = vim.fn.winline() - (vim.fn.winheight(0) / 2) > 0 and 'SW'
    or 'NW'
  local offset = anchor == 'NW' and 1 or 0
  return anchor, offset
end

---Close window with `winnr` if it's a valid window. Additionally allows jumping
---to a specific location in a different window.
---
---@param winnr number
---@param base number? @Window number to make the new active window.
---@param pos [number,number]? @New cursor position as (1,0)-indexed tuple.
function Win:close(winnr, base, pos)
  if not winnr or not vim.api.nvim_win_is_valid(winnr) then
    return
  end

  vim.api.nvim_win_close(winnr, true)
  if base then
    vim.api.nvim_win_set_cursor(base, pos or { 1, 0 })
  end
end

---@package
---Map single line of buffer contents to pure `HlTuple`-array.
---
---@param ln lib.win.ContentLn
---@return HlTuple[]
function Win._map_tuple(ln)
  return vim
    .iter(ln)
    :map(
      ---@param el string|HlTuple
      function(el)
        if type(el) == 'table' then
          assert(
            #el == 2 and type(el[1]) == 'string' and type(el[2]) == 'string',
            'invalid highlight tuple'
          )
          return el
        else
          return { tostring(el), 'Normal' }
        end
      end
    )
    :totable()
end

---@package
---Chunk an `HlTuple`-array. The tuples are assumed to belong to the same screen
---line `i`, where tuples are interspersed with `delim` during rendering.
---
---@param i number @Line index to associate with the generated chunk.
---@param tuples HlTuple[]
---@param delim string? @Delimeter that will be put between text chunks, defaults to ' '.
---@return lib.ui.Chunk[]
function Win._chunk(i, tuples, delim)
  local col = 0

  local chunks = vim
    .iter(tuples)
    :map(
      ---@param t HlTuple
      ---@return lib.ui.Chunk
      function(t)
        local c = {
          text = t[1],
          line = i - 1,
          start = col,
          end_ = col + t[1]:len(),
          hl = t[2],
        } --[[@as lib.ui.Chunk]]

        col = col + t[1]:len() + (delim or ' '):len()
        return c
      end
    )
    :totable()

  return chunks
end

---@package
---Returns a, potentially sparse, array of lines, consisting of the text for
---all included chunks.
---
---The input chunks for each line are expected to appear in order. The generated
---string is constructed by simply appending the text of each chunk to all
---previous ones - no sorting is performed!
---
---TODO: ordering based on target position.
---
---@param chunks lib.ui.Chunk[]
---@return string[]
function Win._chunk_tostring(chunks)
  -- WARN: tbl_values explicitely doesn't guarantee order
  return vim.tbl_values(vim.iter(chunks):fold(
    ---@type string[]
    {},
    ---@param ch lib.ui.Chunk
    function(tbl, ch)
      tbl[ch.line] = tbl[ch.line] and ('%s %s'):format(tbl[ch.line], ch.text)
        or ch.text
      return tbl
    end
  ))
end

---@package
---Apply highlights defined by the chunks to the target buffer.
---
---@param bufnr number
---@param chunks lib.ui.Chunk[]
function Win:_chunk_hl(bufnr, chunks)
  for _, ch in pairs(chunks) do
    vim.hl.range(
      bufnr,
      self.nsid,
      ch.hl or 'Normal',
      { ch.line, ch.start },
      { ch.line, ch.end_ },
      {}
    )
  end
end

---Prefix each line in `content` with a highlighted numerical index, or an
---arbitrary symbol computed dynamically by a call to `symbol`.
---
---@param content string[]|lib.win.ContentLn[]
---@param symbol? fun(i: number): string
---@return lib.win.ContentLn[]
function Win.enumerate(content, symbol)
  if table.isempty(content) then
    return content
  end

  local hl = {
    'DiagnosticError',
    'DiagnosticWarn',
    'DiagnosticInfo',
    'DiagnosticHint',
  }

  return vim
    .iter(ipairs(content))
    :map(
      ---@param i number
      ---@param ln string|lib.win.ContentLn
      ---@return lib.win.ContentLn
      function(i, ln)
        local s = {
          symbol and symbol(i) or tostring(i),
          hl[i % #hl ~= 0 and i % #hl or #hl],
        }

        return {
          s,
          type(ln) == 'string' and ln or unpack(ln --[[@as lib.win.ContentLn]]),
        }
      end
    )
    :totable()
end

---Open floating window.
---
---@param content lib.win.Content @Buffer number or content to render.
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return lib.win.Data
function Win:open(content, enter, config)
  if type(content) == 'number' then
    assert(
      vim.api.nvim_buf_is_valid(content),
      ('invalid buffer: `%d`'):format(content)
    )
  else
    assert(
      type(content) == 'table',
      ('invalid buffer contents: expected table, got %s'):format(type(content))
    )
  end

  ---Transform target content to chunks. This negatively affects performance
  ---when content is a plain string-array.
  ---
  ---PERF: skip content transform when rendering an existing buffer.
  ---
  ---@type lib.ui.Chunk[]
  local ch = vim
    .iter(content)
    :map(
      ---@param el string|lib.win.ContentLn
      function(el)
        return type(el) == 'table' and el or { el }
      end
    )
    :map(
      ---@param ln lib.win.ContentLn
      ---@return HlTuple[]
      function(ln)
        return self._map_tuple(ln)
      end
    )
    :enumerate()
    :map(
      ---@param i number
      ---@param t HlTuple[]
      ---@return lib.ui.Chunk[]
      function(i, t)
        return self._chunk(i, t)
      end
    )
    :flatten(1)
    :totable()

  local lines = self._chunk_tostring(ch)

  local w = self:_width(
    type(content) == 'number' and content
      -- If title is present, ensure that it's not cut off due to buffer
      -- containing only very short lines.
      ---@diagnostic disable-next-line: param-type-mismatch
      or { self.parse_title(config), unpack(lines) }
  )
  local h = self:_height(lines)

  config = vim.tbl_extend('keep', config or {}, {
    relative = type(content) == 'number' and 'editor' or 'cursor',
    anchor = 'NW',
    row = 0,
    col = 0,
    width = w,
    height = h,
    border = 'single',
  } --[[@as vim.api.keyset.win_config]]) --[[@as vim.api.keyset.win_config]]

  ---@type lib.win.Data
  local data = {
    obuf = vim.api.nvim_get_current_buf(),
    owin = vim.api.nvim_get_current_win(),
    nbuf = type(content) == 'number' and content
      or vim.api.nvim_create_buf(false, true),
    nwin = -1,
    config = config,
  }

  data.nwin = vim.api.nvim_open_win(data.nbuf, enter, config)

  if type(content) == 'number' then
    vim.api.nvim_win_set_buf(data.nwin, data.nbuf)
  else
    vim.api.nvim_buf_set_lines(data.nbuf, 0, -1, true, lines)
    self:_chunk_hl(data.nbuf, ch)
  end

  vim.bo[data.nbuf].bufhidden = 'wipe'
  vim.bo[data.nbuf].modifiable = false
  if type(content) == 'table' then
    vim.wo[data.nwin].wrap = true
  end

  return data
end

---Wraps `win.open`, with default position centered relative to editor.
---
---@param content lib.win.Content @Buffer number or content to render.
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return lib.win.Data
function Win:open_center(content, enter, config)
  config = vim.tbl_extend('keep', config or {}, {
    relative = 'editor',
    anchor = 'NW',
    row = ((vim.o.lines - self.max_height()) / 2) - 1,
    col = (vim.o.columns - self.max_width()) / 2,
  } --[[@as vim.api.keyset.win_config]]) --[[@as vim.api.keyset.win_config]]

  return self:open(content, enter, config)
end

---Wraps `win.open`, with default position at cursor. Sets `style` to 'minimal'
---by default.
---
---@param content lib.win.Content @Buffer number or content to render.
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return lib.win.Data
function Win:open_cursor(content, enter, config)
  local anchor, row = self._anchor_offset()

  config = vim.tbl_extend('keep', config or {}, {
    relative = 'cursor',
    anchor = anchor,
    row = row,
    col = -1,
    style = 'minimal',
  } --[[@as vim.api.keyset.win_config]]) --[[@as vim.api.keyset.win_config]]

  return self:open(content, enter, config)
end

return Win

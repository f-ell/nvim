---@class (exact) lib.win.Data
---@field obuf number @Buffer number of previously active buffer.
---@field owin number @Window number of previously active window.
---@field nbuf number @Buffer number of newly opened buffer.
---@field nwin number @Window number of newly opened window.
---@field width integer
---@field height integer
---@field config vim.api.keyset.win_config

---@class lib.Win
local Win = {
  ---@package
  _tbl = require('lib.tbl'),
}

---Maximum window width when `relative` is 'editor'.
local _MAXSIZE = 0.8
---Reuired offset to center floating window when `relative` is 'editor'.
local _OFFSET = (1 - _MAXSIZE) / 2
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
  return math.floor(vim.o.columns * _MAXSIZE) - _HPAD
end

---Calculate maximum window height, maintaining desired padding.
---
---@return integer
function Win.max_height()
  return math.floor(vim.o.lines * _MAXSIZE) - _VPAD
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

  -- FIX: should account for cursor offset (getpos('.')[3]-1)
  -- issue: we don't know if the window will be offset to the left because of
  -- its width
  local maxw = vim.o.columns - _HPAD
  if self._tbl.max_len(data) < maxw then
    return math.min(#data > 0 and #data or 1, self.max_height())
  end

  local h, showbreak = #data, vim.fn.strdisplaywidth(vim.o.showbreak)
  for i = 1, #data do
    local l = vim.fn.strdisplaywidth(data[i])

    -- first wrap
    if l > maxw then
      l = l - maxw
      h = h + 1
    end

    -- subsequent wraps
    while l > maxw do
      l = l - maxw + showbreak
      h = h + 1
    end
  end

  return math.min(h, self.max_height())
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

---Open floating window.
---
---@param lines number|string[] @Buffer number or array over lines to render.
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return lib.win.Data
function Win:open(lines, enter, config)
  ---@type lib.win.Data
  ---@diagnostic disable-next-line: missing-fields
  local data = {
    obuf = vim.api.nvim_get_current_buf(),
    owin = vim.api.nvim_get_current_win(),
    nbuf = -1,
    nwin = -1,
    width = self:_width(
      type(lines) == 'number' and lines
        -- If title is present, ensure that it's not cut off due to buffer
        -- containing only very short lines.
        ---@diagnostic disable-next-line: param-type-mismatch
        or { self.parse_title(config), unpack(lines) }
    ),
    height = self:_height(lines),
  }

  config = vim.tbl_extend('keep', config or {}, {
    relative = type(lines) == 'table' and 'cursor' or 'editor',
    anchor = 'NW',
    row = 1,
    col = type(lines) == 'table' and -1 or math.floor(vim.o.columns * _OFFSET),
    width = data.width,
    height = data.height,
    border = 'single',
  })

  data.nbuf = type(lines) == 'number' and lines
    or vim.api.nvim_create_buf(false, true)
  data.nwin = vim.api.nvim_open_win(data.nbuf, enter, config)

  if type(lines) == 'table' then
    vim.api.nvim_buf_set_lines(data.nbuf, 0, -1, true, lines)
  else
    vim.api.nvim_win_set_buf(data.nwin, data.nbuf)
  end

  data.config = vim.api.nvim_win_get_config(data.nwin)

  vim.bo[data.nbuf].bufhidden = 'wipe'
  vim.bo[data.nbuf].modifiable = false
  if type(lines) == 'table' then
    vim.wo[data.nwin].wrap = true
  end

  return data
end

---Wraps `win.open`, with default position centered relative to editor.
---
---@param lines number|string[] @Buffer number or array over lines to render.
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return lib.win.Data
function Win:open_center(lines, enter, config)
  config = vim.tbl_extend('keep', config or {}, {
    relative = 'editor',
    anchor = 'NW',
    row = math.floor(vim.o.lines * _OFFSET) - 1,
    col = math.floor(vim.o.columns * _OFFSET),
  })

  return self:open(lines, enter, config)
end

---Wraps `win.open`, with default position at cursor. Sets `style` to 'minimal'
---by default.
---
---@param lines number|string[] @Buffer number or array over lines to render.
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return lib.win.Data
function Win:open_cursor(lines, enter, config)
  local anchor, row = self._anchor_offset()

  config = vim.tbl_extend('keep', config or {}, {
    relative = 'cursor',
    anchor = anchor,
    row = row,
    col = -1,
    style = 'minimal',
  })

  return self:open(lines, enter, config)
end

return Win

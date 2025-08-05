---@class lib.Win
local Win = {
  ---@package
  _tbl = require('lib.tbl'),
}

---Maximum window width when `relative` is 'editor'.
Win._MAXSIZE = 0.8
---Reuired offset to center floating window when `relative` is 'editor'.
Win._OFFSET = (1 - Win._MAXSIZE) / 2

---@package
---Extract window title string from `nvim_open_win()`'s `config` table.
--- TODO: export
---
---@param config vim.api.keyset.win_config?
---@return string
function Win._parse_title(config)
  if not (config and config.title) then
    return ''
  end

  return type(config.title) == 'string' and config.title
    or table.concat(
      vim.tbl_map(function(t)
        return t[1]
      end, config.title),
      ''
    )
end

---@package
---Calculate maximum window width, maintaining desired padding.
--- TODO: receiver, export
---
---@return integer
function Win._max_width()
  return math.floor(vim.o.columns * Win._MAXSIZE) - 2
end

---@package
---Calculate maximum window height, maintaining desired padding.
--- TODO: receiver, export
---
---@return integer
function Win._max_height()
  return math.floor(vim.o.lines * Win._MAXSIZE)
end

---@package
---Calculate window width.
--- TODO: receiver
---
---@param data number|string[] buffer | buffer contents
---@return integer
function Win._width(data)
  if type(data) == 'number' then
    return Win._max_width()
  else
    local len = Win._tbl.max_len(data)
    return math.min(len > 0 and len or 1, Win._max_width())
  end
end

---@package
---Calculate window height, respecting wrapped lines and `showbreak`-offset.
--- TODO: receiver
---
---@param data number|string[] buffer | buffer contents
---@return integer
function Win._height(data)
  if type(data) == 'number' then
    return Win._max_height()
  end

  -- FIX: should account for cursor offset (getpos('.')[3]-1)
  -- issue: we don't know if the window will be offset to the left because of
  -- its width
  local maxw = vim.o.columns - 2
  if Win._tbl.max_len(data) < maxw then
    return math.min(#data > 0 and #data or 1, Win._max_height())
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

  return math.min(h, Win._max_height())
end

---Calculate appropriate window anchor and required offset for centering the
---window, based on the current cursor position.
---
---@return 'NW'|'SW' anchor, 0|1 offset
function Win.anchor_offset()
  local anchor = vim.fn.winline() - (vim.fn.winheight(0) / 2) > 0 and 'SW'
    or 'NW'
  local offset = anchor == 'NW' and 1 or 0
  return anchor, offset
end

---Close window if valid.
---
---@param window number
---@param base number? window id to make the new active window
---@param pos {[1]:number,[2]:number}? (1,0)-indexed cursor position
function Win.close(window, base, pos)
  if not window or not vim.api.nvim_win_is_valid(window) then
    return
  end
  vim.api.nvim_win_close(window, true)
  if base then
    vim.api.nvim_win_set_cursor(base, pos or { 1, 0 })
  end
end

---Open floating window.
--- TODO: receiver
---
---@param lines number|string[] buffer number or line-array
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return WinData
function Win.open(lines, enter, config)
  ---@type WinData
  ---@diagnostic disable-next-line: missing-fields
  local data = {
    obuf = vim.api.nvim_get_current_buf(),
    owin = vim.api.nvim_get_current_win(),
    nbuf = -1,
    nwin = -1,
    width = Win._width(
      type(lines) == 'number' and lines
        -- if title is present, ensure that it's not cut off
        ---@diagnostic disable-next-line: param-type-mismatch
        or { Win._parse_title(config), unpack(lines) }
    ),
    height = Win._height(lines),
  }

  config = vim.tbl_extend('keep', config or {}, {
    relative = type(lines) == 'table' and 'cursor' or 'editor',
    anchor = 'NW',
    row = 1,
    col = type(lines) == 'table' and -1
      or math.floor(vim.o.columns * Win._OFFSET),
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

---Wraps `win.open()`, with default position centered relative to editor.
--- TODO: receiver
---
---@param lines number|string[] buffer number or line array
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return WinData
function Win.open_center(lines, enter, config)
  config = vim.tbl_extend('keep', config or {}, {
    relative = 'editor',
    anchor = 'NW',
    row = math.floor(vim.o.lines * Win._OFFSET) - 1,
    col = math.floor(vim.o.columns * Win._OFFSET),
  })

  return Win.open(lines, enter, config)
end

---Wraps `win.open()`, with default position at cursor.
---Sets `style` to 'minimal' by default.
--- TODO: receiver
---
---@param lines number|string[] buffer number or line array
---@param enter boolean
---@param config vim.api.keyset.win_config?
---@return WinData
function Win.open_cursor(lines, enter, config)
  local anchor, row = Win.anchor_offset()

  config = vim.tbl_extend('keep', config or {}, {
    relative = 'cursor',
    anchor = anchor,
    row = row,
    col = -1,
    style = 'minimal',
  })

  return Win.open(lines, enter, config)
end

return Win

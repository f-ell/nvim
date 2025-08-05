---@class lib.Str
local Str = {}

---Return index of last occurence of `pattern` in `str`.
---
---@param str string
---@param pattern string
---@return number?
function Str.rindex(str, pattern)
  local index = str:reverse():find(pattern)

  if not index then
    return nil
  end

  return str:len() - index
end

---Return the word to the left of the current cursor position or `pos`.
---
---Falls back to `vim.fn.expand` when called from normal mode. In that case, the
---returned string will also include any characters to the cursor's right. `pos`
---will be ignored.
---
---@param match_any boolean? @Match against `WORD` instead of `word`.
---@param pos [integer, integer]? @(0,0)-based row-column tuple. Defaults to current cursor position.
---@return string
function Str.word(match_any, pos)
  if vim.api.nvim_get_mode().mode == 'n' then
    return vim.fn.expand(match_any and '<cWORD>' or '<cword>')
  end

  if not pos then
    pos = vim.api.nvim_win_get_cursor(0)
    pos[1] = pos[1] - 1
  end

  local ln = vim.api.nvim_buf_get_lines(0, pos[1], pos[1] + 1, false)[1]
  ln = string.sub(ln, 1, pos[2]):reverse()

  local i = ln:find(match_any and '%s' or '[^%w_]')
  return ln:sub(1, i and (i - 1) or -1):reverse()
end

return Str

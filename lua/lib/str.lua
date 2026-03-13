---@class lib.Str
local Str = {}

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

---Break `str` into multiple lines with at most `width` characters per line.
---
---@param str string
---@param width integer
---@param preserve boolean? @Whether to preserve indentation in wrapped lines. Only relevant when `str` starts with whitespace. Defaults to `true`.
---@return string[]
function Str:wrap(str, width, preserve)
  if str:len() <= width then
    return { str }
  end

  ---@type string[]
  local tbl = {}

  local indent = ''
  if preserve or preserve == nil then
    indent = str:match('^(%s+)') or ''
  end

  local i, j = 0, width

  -- First line must not be trimmed; insert separately.
  table.insert(tbl, vim.fn.slice(str, i, j))
  i, j = j, j + width - indent:len()

  while j < str:len() do
    table.insert(tbl, vim.trim(vim.fn.slice(str, i, j)))
    i, j = j, j + width - indent:len()
  end

  table.insert(tbl, vim.trim(vim.fn.slice(str, i)))

  return {
    tbl[1],
    unpack(vim
      .iter(tbl)
      :skip(1)
      :map(function(ln)
        return indent .. ln
      end)
      :totable()),
  }
end

return Str

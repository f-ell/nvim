---@alias Location lsp.Range

---@param str string
---@param cursor number
---@param match fun(_: any, c: string)
---@return number?
local function scan_left(str, cursor, match)
  return vim.iter(vim.split(str, '')):take(cursor - 1):enumerate():rfind(match)
end

---@param str string
---@param cursor number
---@param match fun(_: any, c: string)
---@return number?
local function scan_right(str, cursor, match)
  return vim.iter(vim.split(str, '')):skip(cursor - 1):enumerate():find(match)
end

---Returns the text (i.e. number to transform) at the given position (as
---returned by `getpos`) for the given mode, along with its buffer position.
---
---@param mode vim.api.keyset.get_mode
---@param curpos integer[]
---@return string, Location
local function get_word(mode, curpos)
  local m = mode.mode:lower():sub(1, 1)
  ---@type string, Location
  local str, pos

  ---Match on space or tab.
  ---
  ---@param c string
  local match = function(_, c)
    local b = c:byte(1, 1)
    return b == 0x20 or b == 0x9
  end

  -- Non-exhaustive, bare-minimum mode checks.
  if m == 'v' then -- Use visual marks to determine source boundaries.
    local a = vim.fn.getpos('v')
    local b = curpos
    if a[2] < b[2] or (a[2] == b[2] and a[3] > b[3]) then
      a, b = b, a
    end

    str = table.concat(vim.api.nvim_buf_get_text(0, a[2], a[3], b[2], b[3], {}))
    pos = {
      start = { line = a[2], character = a[3] },
      ['end'] = { line = b[2], character = b[3] },
    }
  elseif m == 'i' then -- Scan to left word boundary.
    local ln =
      vim.api.nvim_buf_get_text(0, curpos[2], 0, curpos[2], curpos[3], {})[1]
    local i = scan_left(ln, curpos[3], match)
    i = i == nil and 1 or i + 1

    str = ln:sub(i)
    pos = str == '' and {}
      or {
        start = { line = curpos[2] - 1, character = i - 1 },
        ['end'] = { line = curpos[2] - 1, character = -1 },
      }
  else -- Scan left and right word boundaries in all other modes.
    local ln = vim.api.nvim_buf_get_lines(0, curpos[2] - 1, curpos[2], true)[1]

    local i = scan_left(ln, curpos[3], match)
    local j = scan_right(ln, curpos[3], match)
    i = i == nil and 1 or i + 1
    j = j == nil and ln:len() or j - 1

    str = ln:sub(i, j)
    pos = str == '' and {}
      or {
        start = { line = curpos[2] - 1, character = i - 1 },
        ['end'] = { line = curpos[2] - 1, character = j },
      }
  end

  return str, pos
end

---Supported conversion bases.
---
---@type table<string, fun(i:any):string>
local convert = {
  dec = function(from)
    return ('%d'):format(from)
  end,
  hex = function(from)
    return ('0x%x'):format(from)
  end,
}

vim.api.nvim_create_user_command('Num', function(args)
  if not convert[args.fargs[1]] then
    vim.notify(
      ('Invalid conversion: %s'):format(args.fargs[1]),
      vim.log.levels.ERROR
    )
    return
  end

  if not vim.bo.modifiable then
    vim.notify('Not modifiable', vim.log.levels.ERROR)
    return
  end

  local from, pos = get_word(vim.api.nvim_get_mode(), vim.fn.getpos('.'))

  if from == '' then
    vim.notify('No word under cursor', vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_buf_set_text(
    0,
    pos.start.line,
    pos.start.character,
    pos['end'].line,
    pos['end'].character,
    { convert[args.fargs[1]](tonumber(from) or 0) }
  )
end, {
  nargs = 1,
  complete = function()
    local keys = vim.fn.keys(convert)
    table.sort(keys)
    return keys
  end,
  desc = 'Translate between different number formats.',
})

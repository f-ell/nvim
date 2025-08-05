---@class lib.IO
local IO = {}

---@package
---Open `file` if it's not been opened already.
---
---@param file string|file* @Name or handle to open.
---@param mode openmode
---@return file*|nil
function IO._open(file, mode)
  if type(file) == 'string' then
    return io.open(file, mode) --[[@as file*]]
  end

  return file
end

---Read contents of `file`. Returns an emtpy string in case of errors.
--- TODO: receiver
---
---@param file string|file* @Name or handle of file to open. Closed automatically.
---@param chop boolean? @Remove trailing newline. Defaults to `false`.
---@return string
function IO.read(file, chop)
  local fh = IO._open(file, 'r')
  if fh == nil then
    return ''
  end

  local str = fh:read('*a')
  fh:close()
  return chop and str:sub(0, str:len() - 1) or str
end

---Read file contents to consecutive table indices. Returns an emtpy table in
---case of errors.
--- TODO: receiver
---
---@param file string|file* @Name or handle of file to open. Closed automatically.
---@return string[]
function IO.tbl_read(file)
  local fh = IO._open(file, 'r')
  if fh == nil then
    return {}
  end

  local tbl = vim.iter(fh:lines()):totable()

  fh:close()
  return tbl
end

---Write `data` to `file`.
--- TODO: receiver
---
---@param file string|file* @Name or handle of file to open. Closed automatically.
---@param data string[]
---@param mode 'w'|'w+'|'wb'|'w+b'? @Defaults to 'w+'.
function IO.write(file, data, mode)
  assert(
    vim.tbl_contains({ 'w', 'w+', 'wb', 'w+b' }, mode),
    'illegal mode: ' .. mode
  )

  local fh = IO._open(file, mode or 'w+')
  assert(fh ~= nil, ('failed to open: %s'):format(file))

  fh:write(table.concat(data, '\n') .. '\n')
  fh:flush()
  fh:close()
end

return IO

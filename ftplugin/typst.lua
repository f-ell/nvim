vim.wo[0][0].spell = true

---@class Position (exact)
---@field index number
---@field value string

---@param args string[]
---@return Position?
local function get_value(args)
  local i = 1
  while i <= #args do
    local str = vim.fn.trim(args[i])

    local parts = vim.split(str, '=', { plain = true })
    if not vim.startswith(parts[1], '--input') then
      goto continue
    end

    if #parts == 1 then
      return nil
    end

    parts = { unpack(parts, 2) }
    if parts[1] == 'img' then
      return { index = i, value = parts[2] }
    end

    ::continue::
    i = i + 1
  end

  return nil
end

--- Update tinymist's configuration to dynamically toggle between compiling in
--- and excluding images.
vim.api.nvim_create_user_command('Image', function()
  local client = vim.lsp.get_clients({ name = 'tinymist' })[1]
  if not client then
    vim.notify('No client found for `tinymist`', vim.log.levels.ERROR)
    return
  end

  local args = client.settings.typstExtraArgs --[[@as table?]] or {}
  local pos = get_value(args)
  local target

  -- Images are omitted by default. Calling this user command for the first time
  -- when no input argument exists indicates the desire to change from whatever
  -- the default value is.
  if pos == nil then
    table.insert(args, '--input=img=1')
    target = 1
    goto restart
  end

  if pos.value == '0' then
    target = 1
  elseif pos.value == '1' then
    target = 0
  else
    vim.notify(('Invalid input state `%s`'):format(pos), vim.log.levels.ERROR)
    return
  end

  client.settings.typstExtraArgs[pos.index] = '--input=img=' .. target
  ::restart::
  client:_restart()

  if target == 1 then
    vim.notify('Image compilation enabled')
  else
    vim.notify('Image compilation disabled')
  end
end, {})

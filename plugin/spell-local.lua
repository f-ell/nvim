-- Dynamically detecs spellfiles in the buffer's base- or any of its parent
-- directories (see 'spellname' below). Allows scoping spellfiles to certain
-- directories / projects. Respects global spellfile setting, as well as
-- spellfiles added dynamically at runtime, though local spellfiles will always
-- have higher priority.
--
-- 1. walk the directory tree down to the directory
--   (a) of the first editing buffer (i.e. dirname), or
--   (b) to the directory nvim was invoked from (i.e. cwd)
-- 2. at each level, check for the existence of a local spellfile (see
-- 'spellname' below)
-- 3. if found, prepend spellfile to 'spellfile'

local spellname = '.spell-local.utf-8.add'
local state = {
  spellfiles = {} --[[@type table<string>]],
  mkspell = nil --[[@type integer]],
}

vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  pattern = '*',
  callback = function()
    local cwd = vim.fn.expand('%:p') --[[@as string|nil]]
    if cwd == '' then
      cwd = vim.uv.cwd()
      ---@cast cwd -nil
    end
    cwd = cwd:gsub('^.-://', '')

    local stat = vim.uv.fs_stat(cwd)
    if (stat and stat.type == 'file') or not stat then
      cwd = vim.fs.dirname(cwd)
    end

    if not vim.endswith(cwd, '/') then
      cwd = cwd .. '/'
    end

    local dir = ''
    local files = vim.bo.spellfile ~= '' and vim.fn.split(vim.bo.spellfile, ',')
      or {}

    for d in cwd:sub(2):gmatch('([^/]-)/') do
      dir = dir .. '/' .. d
      local file = dir .. '/' .. spellname

      stat = vim.uv.fs_stat(file)
      if stat and stat.type == 'file' then
        table.insert(files, 1, file)
      end
    end

    -- incurs a potentially significant runtime cost, but respects the users
    -- global spellfile, as well as any that are added at runtime
    local uniq = {}
    for _, v in ipairs(files) do
      if not vim.tbl_contains(uniq, v) then
        table.insert(uniq, v)
      end
    end

    state.spellfiles = uniq
    vim.bo.spellfile = table.concat(uniq, ',')
  end,
})

vim.api.nvim_create_user_command('SpellEdit', function()
  if #state.spellfiles == 0 then
    vim.notify('No spellfiles found', vim.log.levels.INFO)
    return
  end

  if state.mkspell ~= nil then
    vim.api.nvim_del_autocmd(state.mkspell)
  end
  state.mkspell = vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = state.spellfiles,
    command = 'mkspell %!',
  })

  vim.fn.setqflist(vim
    .iter(state.spellfiles)
    :map(function(s)
      return {
        filename = s,
        lnum = 1,
        col = 1,
        valid = true,
      }
    end)
    :totable())
  vim.cmd('copen')
end, {})

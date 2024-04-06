local M = {}
M.cmd = {}
M.fs = {}
M.io = {}
M.lsp = {}
M.str = {}
M.tbl = {}
M.ui = {}
M.win = {}
M.key = {}

---------------------------------------------------------------------------- cmd

---Register buffer-local autocommand on `events`.
---
---@param events string|string[]
---@param buffer number
---@param callback string|function
function M.cmd.event(events, buffer, callback)
  vim.defer_fn(function()
    vim.api.nvim_create_autocmd(events, {
      buffer = buffer,
      nested = true,
      callback = type(callback) == 'string' and callback or function(tbl)
        callback(tbl)
      end,
    })
  end, 0)
end

----------------------------------------------------------------------------- fs

---Temporary user directory for local storage. Contains trailing slash!
M.fs.user_dir = vim.fn.stdpath('run') .. '/nvim.user/'

---Generate unique version of `name` with postfix numbering.
---
---@param name string
---@return string filename
function M.fs._unique(name)
  if not vim.loop.fs_stat(name) then
    return name
  end

  local i = 1
  name = name .. '-' .. i
  while vim.loop.fs_stat(name) do
    i = i + 1
    name = name:sub(0, -2) .. i
  end

  return name
end

---Current process PID. Linux only - relies on `/proc/self/status`!
M.fs._PID = (function()
  for ln in io.lines('/proc/self/status') do
    local match = ln:match('^Pid:.-(%d+)$')
    if match then
      return match
    end
  end
end)()

---Create temporary directory for miscellaneous runtime user files.
function M.fs.mktmpdir()
  if vim.loop.fs_stat(M.fs.user_dir) then
    return
  end

  assert(
    vim.loop.fs_mkdir(M.fs.user_dir, 448),
    "couldn't create " .. M.fs.user_dir
  )
end

---Write to temporary file.
---
---@param buffer number
---@param data string[]
---@param remove boolean register delete autocommand
---@param name string? basename of the file to write or uniquely generated name
---@return string filename
function M.fs.writetmpfile(buffer, data, remove, name)
  if not vim.loop.fs_stat(M.fs.user_dir) then
    M.fs.mktmpdir()
  end

  local file = M.fs.user_dir .. (name and name or M.fs._PID .. '-' .. buffer)
  M.io.write(name and file or M.fs._unique(file), data)

  if remove then
    vim.api.nvim_create_autocmd(
      { 'BufDelete', 'BufUnload', 'BufWipeout', 'VimLeavePre' },
      {
        buffer = buffer,
        callback = function()
          os.remove(file)
        end,
        once = true,
      }
    )
  end

  return file
end

----------------------------------------------------------------------------- io

---Open `file` if necessary.
---
---@param file string|file* name or handle
---@param mode string
---@return file*|nil filehandle
function M.io._open(file, mode)
  if type(file) == 'string' then
    return io.open(file, mode) --[[@as file*]]
  else
    return file
  end
end

---Read contents of `file`.
---
---@param file string|file* closed automatically
---@param chop boolean? remove trailing newline
---@return string content
function M.io.read(file, chop)
  local fh = M.io._open(file, 'r')
  if fh == nil then
    return ''
  end

  local str = fh:read('*a')
  fh:close()
  return chop and str:sub(0, str:len() - 1) or str
end

---Read file contents to consecutive table indices.
---
---@param file string|file* closed automatically
---@return string[] content
function M.io.tbl_read(file)
  local fh = M.io._open(file, 'r')
  if fh == nil then
    return {}
  end

  local tbl = {}
  for ln in fh:lines() do
    table.insert(tbl, ln)
  end
  fh:close()
  return tbl
end

---Write `data` to `file`.
---
---@param file string|file* closed automatically
---@param data string[]
---@param mode 'w'|'w+'|'wb'|'w+b'? defaults to w+
function M.io.write(file, data, mode)
  if mode and not vim.tbl_contains({ 'w', 'w+', 'wb', 'w+b' }, mode) then
    error('illegal mode - ' .. mode)
  end

  local fh = M.io._open(file, mode or 'w+')
  assert(fh ~= nil, ('Failed to write `%s`'):format(file))

  fh:write(table.concat(data, '\n') .. '\n')
  fh:flush()
  fh:close()
end

---------------------------------------------------------------------------- lsp

---Apply a workspace edit.
---
---@param response EnrichedLspResponse
function M.lsp.apply_edit(response)
  local edit = response.result.edit and response.result.edit or response.result

  vim.lsp.util.apply_workspace_edit(
    edit,
    vim.lsp.get_client_by_id(response.id).offset_encoding
  )

  if response.result.action and type(response.result.action) == 'function' then
    response.result.action()
  end
end

---Get all lsp clients with capability `cap` .. "Provider" attached to the
---buffer.
---
---@param capabilities string|string[]
---@param filter (fun(client:LspClient):boolean)? determines whether a client is returned
---@return LspClient[] clients
function M.lsp.clients_by_cap(capabilities, filter)
  local clients = vim.tbl_filter(
    function(client)
      if type(capabilities) == 'string' then
        return not not client.server_capabilities[capabilities .. 'Provider']
      end

      for i = 1, #capabilities do
        if not client.server_capabilities[capabilities[i] .. 'Provider'] then
          return false
        end
      end

      return true
    end,
    vim.lsp.get_active_clients({
      buffer = vim.api.nvim_get_current_buf(),
    })
  )

  if filter then
    clients = vim.tbl_filter(filter, clients)
  end

  if #clients == 0 then
    vim.notify('No client(s) found', vim.log.levels.INFO)
  end
  return clients
end

---Format and print RequestError via `vim.notify()`
---
---@param errors RequestError|RequestError[]
---@param level LogLevel? defaults to `vim.log.levels.ERROR`
function M.lsp.notify_error(errors, level)
  errors = type(errors[1]) == 'table' and errors or { errors }
  for i = 1, #errors do
    vim.notify(
      ('%s: `%s` request failed%s'):format(
        errors[i].name,
        errors[i].method,
        errors[i].message and ' - ' .. errors[i].message or ''
      ),
      level or vim.log.levels.ERROR
    )
  end
end

---Aggregate responses of all clients.
---Ignores global handlers (i.e. `vim.lsp.handlers`), but respects client-local
---handlers. Handlers on clients are expected to return `{ err, result }`-tuples.
---
---@param clients LspClient|LspClient[]
---@param method string
---@param params TextDocumentPositionParams
---@param bufnr number
---@param timeout number? passeed as `timeout` parameter to `wait()`, defaults to 1000
---@return RequestError[]?,EnrichedLspResponse[]
function M.lsp.request(clients, method, params, bufnr, timeout)
  if
    type(clients) == 'table'
    and not (type(clients[1]) == 'table' or M.tbl.is_empty(clients))
  then
    clients = { clients }
  end

  local errors, responses = {}, {}

  ---@diagnostic disable-next-line: redefined-local
  local function add_err(name, method, message)
    table.insert(errors, { name = name, method = method, message = message })
  end
  local function add_res(id, name, result)
    table.insert(responses, { id = id, name = name, result = result })
  end

  for i = 1, #clients do
    local handler = function(err, result, ctx, config)
      local res, msg
      local _h = clients[i].handlers[method]

      if _h then
        local ok
        ok, res = pcall(_h, err, result, ctx, config or {})

        -- FIX: poor implementation, should not be nested in async-request
        if not ok then
          res = clients[i].request_sync(method, params, 800, bufnr)
        end
      else
        res = { err = err, result = result }
      end

      if not res then
        add_err(clients[i].name, method, msg)
        goto continue
      end
      if res.err then
        add_err(clients[i].name, method, res.err.message)
        goto continue
      end
      if M.tbl.is_empty(res.result) then
        goto continue
      end

      res.result = type(res.result[1]) == 'table' and res.result
        or { res.result }
      for j = 1, #res.result do
        add_res(clients[i].id, clients[i].name, res.result[j])
      end
      ::continue::
    end

    local status, request = clients[i].request(method, params, handler, bufnr)
    if status == false then
      return {
        name = clients[i].name,
        method = method,
        message = 'cliet not available',
      }, {}
    end

    local wait = vim.fn.wait(timeout or 1000, function()
      return clients[i].requests[request] == nil
    end, 50)

    if wait == -1 then
      return {
        name = clients[i].name,
        method = method,
        message = 'timeout',
      }, {}
    elseif wait == -2 then
      return {
        name = clients[i].name,
        method = method,
        message = 'interrupt',
      }, {}
    elseif wait == -3 then
      return {
        name = clients[i].name,
        method = method,
        message = 'internal error',
      }, {}
    end
  end

  return #errors > 0 and errors or nil, responses
end

---------------------------------------------------------------------------- str

---Return index of last occurence of `pattern` in `str`.
---
---@param str string
---@param pattern string
---@return number?
function M.str.last_index(str, pattern)
  local index = str:reverse():find(pattern)

  if not index then
    return nil
  end

  return str:len() - index
end

---------------------------------------------------------------------------- tbl

---Perform recursive concatenation of two nested array-like tables.
---
---@param tbl number|string|table<string, number, table<string, number>>
---@param sep string
---@return string
function M.tbl.deep_concat(tbl, sep)
  if type(tbl) ~= 'table' then
    return string.format(tbl)
  end

  return table.concat(
    vim.tbl_map(function(t)
      return type(t) ~= 'table' and t or M.tbl.deep_concat(t, sep)
    end, tbl),
    sep
  )
end

---Return the display width of the longest item in `tbl`.
---
---@param tbl string[]
---@return integer
function M.tbl.max_len(tbl)
  local max = 0
  for i = 1, #tbl do
    local len = vim.fn.strwidth(tbl[i])
    if len > max then
      max = len
    end
  end
  return max
end

---Check if table is empty, i.e. contains any non-nil values.
---
---@param tbl table?
---@return boolean
function M.tbl.is_empty(tbl)
  return tbl == nil or (type(tbl) == 'table' and next(tbl) == nil)
end

----------------------------------------------------------------------------- ui

---Register events to automatically close window `winnr`.
---
---@param bufnr number
---@param winnr number
function M.ui._register_close_events(bufnr, winnr)
  M.cmd.event({ 'WinLeave', 'QuitPre' }, bufnr, function()
    M.win.close(winnr)
  end)

  M.key.nnmap('<C-c>', function()
    M.win.close(winnr)
  end, { buffer = bufnr })
end

---Register buffer-local keymaps to select items.
---
---@param bufnr number
---@param callback fun(index:number)
function M.ui._register_select_keymaps(bufnr, callback)
  M.key.nnmap('<CR>', function()
    callback(vim.fn.line('.'))
  end, { buffer = bufnr })

  for i = 1, #vim.api.nvim_buf_get_lines(bufnr, 0, -1, true) do
    M.key.nnmap(tostring(i), function()
      callback(i)
    end, { buffer = bufnr })
  end
end

---Open floating window and allow selection of zero or more items, returning all
---selected items.
---
---`multi`:
---If `true`, allow selection of multiple items. If `false`, pre-select the
---first item and disallow multiple selections; the function will return `T[]`
---regardless.
---
---If array, it's interpreted as indices of items to pre-select. As a special
---case, if the first element is `-1`, all items are pre-selected; subsequent
---indices are ignored.
---
---NOTE: `getchar()` does not allow the visual cursor to update properly before
---0.10.
---
---@generic T
---@param items T[]
---@param multi boolean|number[]
---@param format fun(item:T,selected:boolean,index:number):string transform item to string representation
---@param config table? config passed to `nvim_open_win()`
---@return T[] selected
function M.ui.pick(items, multi, format, config)
  if M.tbl.is_empty(items) then
    return {}
  end

  local function set_highlights(bufnr)
    -- FIX: don't rely on diagnostic signs being set
    local signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
      return vim.startswith(s.name, 'DiagnosticSign')
    end)

    for i = 1, #vim.api.nvim_buf_get_lines(bufnr, 0, -1, true) do
      vim.api.nvim_buf_add_highlight(
        bufnr,
        -1,
        signs[i % #signs ~= 0 and i % #signs or #signs].texthl,
        i - 1,
        0,
        string.len(i)
      )
    end
  end

  do
    local sparse = {}
    if type(multi) == 'table' and multi[1] == -1 then
      for i = 1, #items do
        sparse[i] = true
      end
    elseif type(multi) == 'table' then
      for i = 1, #multi do
        sparse[multi[i]] = true
      end
    elseif multi == false then
      sparse[1] = true
    end

    local tbl = {}
    for i = 1, #items do
      table.insert(tbl, { item = items[i], selected = sparse[i] })
    end
    items = tbl
  end

  local lines = {}
  for i = 1, #items do
    table.insert(lines, i .. ' ' .. format(items[i].item, items[i].selected, i))
  end

  local data = M.win.open_cursor(lines, true, config)
  set_highlights(data.nbuf)

  M.ui._register_close_events(data.nbuf, data.nwin)

  local function select(i)
    vim.api.nvim_win_set_cursor(data.nwin, { i, 0 })

    if multi == false then
      for j = 1, #items do
        items[j].selected = false
        lines[j] = j .. ' ' .. format(items[j].item, items[j].selected, j)
      end
      items[i].selected = true
      lines[i] = i .. ' ' .. format(items[i].item, items[i].selected, i)
    else
      items[i].selected = not items[i].selected
      lines[i] = i .. ' ' .. format(items[i].item, items[i].selected, i)
    end

    vim.bo[data.nbuf].modifiable = true
    vim.api.nvim_buf_set_lines(data.nbuf, 0, -1, true, lines)
    vim.bo[data.nbuf].modifiable = false
    vim.api.nvim_win_set_width(
      data.nwin,
      M.win._width({ M.win._parse_title(config), unpack(lines) })
    )
    set_highlights(data.nbuf)
  end

  local i_indices = {}
  for i = 1, #items do
    table.insert(i_indices, i)
  end
  local vmaps = { 22, 86, 118 }

  while true do
    vim.cmd('redraw!')
    local c, num = vim.fn.getchar(), nil

    if c == 27 then
      break
    end

    if c == 13 then
      select(vim.fn.line('.'))
      goto continue
    end

    if vim.tbl_contains(vmaps, c) then
      goto continue
    end

    num = tonumber(vim.fn.nr2char(c))
    if num then
      if num <= #items then
        select(num)
      end
      goto continue
    end

    -- NOTE: does not handle operator-pending mappings
    vim.fn.feedkeys(vim.fn.nr2char(c), 'x')

    ::continue::
  end

  M.win.close(data.nwin)

  local tbl = {}
  for i = 1, #items do
    if items[i].selected then
      table.insert(tbl, items[i].item)
    end
  end

  return tbl
end

---------------------------------------------------------------------------- win

---Maximum window width when `relative` is 'editor'.
M.win._MAXSIZE = 0.8
---Reuired offset to center floating window when `relative` is 'editor'.
M.win._OFFSET = (1 - M.win._MAXSIZE) / 2

---Extract window title string from `nvim_open_win()`'s `config` table.
---
---@param config table?
---@return string
function M.win._parse_title(config)
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

---Calculate maximum window width, maintaining desired padding.
---
---@return integer
function M.win._max_width()
  return math.floor(vim.o.columns * M.win._MAXSIZE) - 2
end

---Calculate maximum window height, maintaining desired padding.
---
---@return integer
function M.win._max_height()
  return math.floor(vim.api.nvim_win_get_height(0) * M.win._MAXSIZE)
end

---Calculate window width.
---
---@param data number|string[] buffer | buffer contents
---@return integer
function M.win._width(data)
  if type(data) == 'number' then
    return M.win._max_width()
  else
    local len = M.tbl.max_len(data)
    return math.min(len > 0 and len or 1, M.win._max_width())
  end
end

---Calculate window height, respecting wrapped lines and `showbreak`-offset.
---
---@param data number|string[] buffer | buffer contents
---@return integer
function M.win._height(data)
  if type(data) == 'number' then
    return M.win._max_height()
  end

  local maxw = vim.o.columns - 2
  if M.tbl.max_len(data) < maxw then
    return math.min(#data > 0 and #data or 1, M.win._max_height())
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

  return math.min(h, M.win._max_height())
end

---Calculate appropriate window anchor and required offset for centering the
---window, based on the current cursor position.
---
---@return 'NW'|'SW' anchor, 0|1 offset
function M.win.anchor_offset()
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
function M.win.close(window, base, pos)
  if not window or not vim.api.nvim_win_is_valid(window) then
    return
  end
  vim.api.nvim_win_close(window, true)
  if base then
    vim.api.nvim_win_set_cursor(base, pos or { 1, 0 })
  end
end

---Return whether `window` is a valid window handle and the currently active
---window.
---
---@param window number
---@return boolean
function M.win.is_cur_valid(window)
  return (
    vim.api.nvim_get_current_win() == window
    and vim.api.nvim_win_is_valid(window)
  )
end

---Open floating window.
---
---@param lines number|string[] buffer number or line-array
---@param enter boolean
---@param config table? config passed to `nvim_open_win()`
---@return WinData
function M.win.open(lines, enter, config)
  ---@type WinData
  local data = {
    obuf = vim.api.nvim_get_current_buf(),
    owin = vim.api.nvim_get_current_win(),
    nbuf = -1,
    nwin = -1,
    width = M.win._width(
      type(lines) == 'number' and lines
        -- if title is present, ensure that it's not cut off
        ---@diagnostic disable-next-line: param-type-mismatch
        or { M.win._parse_title(config), unpack(lines) }
    ),
    height = M.win._height(lines),
  }

  ---@diagnostic disable-next-line: redefined-local
  local config = vim.tbl_extend('keep', config or {}, {
    relative = type(lines) == 'table' and 'cursor' or 'editor',
    anchor = 'NW',
    row = 1,
    col = type(lines) == 'table' and -1
      or math.floor(vim.o.columns * M.win._OFFSET),
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

  vim.bo[data.nbuf].bufhidden = 'wipe'
  vim.bo[data.nbuf].modifiable = false
  if type(lines) == 'table' then
    vim.wo[data.nwin].wrap = true
  end

  return data
end

---Wraps `win.open()`, with default position centered relative to editor.
---
---@param lines number|string[] buffer number or line array
---@param enter boolean
---@param config table? config passed to `nvim_open_win()`
---@return WinData
function M.win.open_center(lines, enter, config)
  config = vim.tbl_extend('keep', config or {}, {
    relative = 'editor',
    anchor = 'NW',
    row = math.floor(vim.o.lines * M.win._OFFSET) - 1,
    col = math.floor(vim.o.columns * M.win._OFFSET),
  })

  return M.win.open(lines, enter, config)
end

---Wraps `win.open()`, with default position at cursor.
---Sets `style` to 'minimal' by default.
---
---@param lines number|string[] buffer number or line array
---@param enter boolean
---@param config table? config passed to `nvim_open_win()`
---@return WinData
function M.win.open_cursor(lines, enter, config)
  local anchor, row = M.win.anchor_offset()

  config = vim.tbl_extend('keep', config or {}, {
    relative = 'cursor',
    anchor = anchor,
    row = row,
    col = -1,
    style = 'minimal',
  })

  return M.win.open(lines, enter, config)
end

---------------------------------------------------------------------------- key

---Disable keymaps to enter visual mode in buffer `bufnr`.
---
---@param bufnr number
function M.key._disable_visual_keymaps(bufnr)
  for _, lhs in pairs({ 'v', 'V', '<C-v>' }) do
    M.key.nnmap(lhs, '', { buffer = bufnr })
  end
end

---Create mapping function for `mode`.
---
---@param mode 'i'|'n'|'v'|'c'|'t'
---@param map_opts table?
---@return fun(lhs:string,rhs:string|function,opts:table?)
function M.key._map(mode, map_opts)
  map_opts = map_opts or { noremap = true }
  ---Wraps vim.keymap.set. The mode is derived from the overarching call.
  ---
  ---@param lhs string
  ---@param rhs string|function
  ---@param opts table?
  return function(lhs, rhs, opts)
    opts = vim.tbl_extend('force', map_opts, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

M.key.inmap = M.key._map('i')
M.key.nnmap = M.key._map('n')
M.key.vnmap = M.key._map('v')
M.key.cnmap = M.key._map('c')
M.key.tnmap = M.key._map('t')

---Set map for one or more modes.
---
---@param modes string|string[]
---@param lhs string
---@param rhs string|function
---@param opts table?
function M.key.modemap(modes, lhs, rhs, opts)
  opts = vim.tbl_extend('force', { noremap = true }, opts or {})
  vim.keymap.set(modes, lhs, rhs, opts)
end

---Delete map for one or more modes.
---
---@param modes string|string[]
---@param lhs string
---@param opts table?
function M.key.unmap(modes, lhs, opts)
  vim.keymap.del(modes, lhs, opts or {})
end

return M

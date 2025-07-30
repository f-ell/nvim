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

---@package
---Generate unique version of `name` with postfix numbering.
---
---@param name string
---@return string filename
function M.fs._unique(name)
  if not vim.uv.fs_stat(name) then
    return name
  end

  local i = 1
  name = name .. '-' .. i
  while vim.uv.fs_stat(name) do
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
  if vim.uv.fs_stat(M.fs.user_dir) then
    return
  end

  assert(
    vim.uv.fs_mkdir(M.fs.user_dir, 448),
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
  if not vim.uv.fs_stat(M.fs.user_dir) then
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

---@package
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
---@param response LspResponse
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

---Format and print RequestError via `vim.notify()`
---
---@param errors RequestError|RequestError[]
---@param level vim.log.levels? defaults to `vim.log.levels.ERROR`
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
---@param clients vim.lsp.Client|vim.lsp.Client[]
---@param method string
---@param params table
---@param bufnr number? buffer to use for requests, defaults to `0`
---@param timeout number? passed as `timeout` parameter to `wait()`, defaults to `2000`
---@return RequestError[]?,LspResponse[]
function M.lsp.request(clients, method, params, bufnr, timeout)
  if
    type(clients) == 'table'
    and not (type(clients[1]) == 'table' or M.tbl.isempty(clients))
  then
    clients = { clients }
  end

  bufnr = bufnr or 0
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
          res = clients[i]:request_sync(method, params, 800, bufnr)
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
      if M.tbl.isempty(res.result) then
        goto continue
      end

      res.result = type(res.result[1]) == 'table' and res.result
        or { res.result }
      for j = 1, #res.result do
        add_res(clients[i].id, clients[i].name, res.result[j])
      end
      ::continue::
    end

    local status, request = clients[i]:request(method, params, handler, bufnr)
    if status == false then
      return {
        name = clients[i].name,
        method = method,
        message = 'client not available',
      }, {}
    end

    local wait = vim.fn.wait(timeout or 2000, function()
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

---Return the word to the left of the cursor.
---
---Falls back to `vim.fn.expand` when called from normal mode. As a result, when
---called this way, this will also return any characters to the cursor's right.
---In this case, `pos` is ignored.
---
---@param match_any boolean|nil match WORD instead of word
---@param pos [integer, integer]|nil (0,0)-based row-column tuple
function M.str.word(match_any, pos)
  if vim.api.nvim_get_mode().mode == 'n' then
    return vim.fn.expand(match_any and '<cWORD>' or '<cword>')
  end

  if not pos then
    pos = vim.api.nvim_win_get_cursor(0)
    pos[1] = pos[1] - 1
  end

  -- local col = vim.api.nvim_win_get_cursor(0)[2]
  local ln = vim.api.nvim_buf_get_lines(0, pos[1], pos[1] + 1, false)[1]
  ln = string.sub(ln, 1, pos[2]):reverse()

  -- FIX: does %W include `_`?
  local index = ln:find(match_any and '%s' or '%W')
  return ln:sub(1, index and (index - 1) or -1):reverse()
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
    local len = vim.fn.strcharlen(tbl[i])
    if len > max then
      max = len
    end
  end
  return max
end

---Returns `true` if table is empty or `nil`.
---
---@param tbl table?
---@return boolean
function M.tbl.isempty(tbl)
  return tbl == nil or vim.tbl_isempty(tbl)
end

----------------------------------------------------------------------------- ui

---@package
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

---@package
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

---@package
---Apply highlights for the given chunks in the given buffer.
---
---@param bufnr number
---@param nsid number
---@param chunks Chunk[]
function M.ui._highlight(bufnr, nsid, chunks)
  local texthl = {
    'DiagnosticError',
    'DiagnosticWarn',
    'DiagnosticInfo',
    'DiagnosticHint',
  }

  for i = 1, #vim.api.nvim_buf_get_lines(bufnr, 0, -1, true) do
    vim.hl.range(
      bufnr,
      nsid,
      texthl[i % #texthl ~= 0 and i % #texthl or #texthl],
      { i - 1, 0 },
      { i - 1, string.len(i) },
      { priority = vim.hl.priorities.user + 1 }
    )
  end

  for _, ch in pairs(chunks) do
    vim.hl.range(
      bufnr,
      nsid,
      ch.hl or 'Normal',
      { ch.line, ch.start },
      { ch.line, ch.end_ }
    )
  end
end

---@package
---Update selected indices based on `mode` at the index given by `i`.
---
---@param winnr number
---@param mode Mode
---@param i number @0-based cursor line index.
---@param selected boolean[] @Sparse array for selected item indices. Updated in place!
---@return number[] @The indices of all items whose selection has changed.
function M.ui._select(winnr, mode, i, selected)
  vim.api.nvim_win_set_cursor(winnr, { i, 0 })
  local tbl = {}

  if mode == 'no' then
    if selected[i] then
      return tbl
    end

    for j, _ in pairs(selected) do
      selected[j] = nil
      table.insert(tbl, j)
    end

    selected[i] = true
    table.insert(tbl, i)
  elseif mode == 'instant' then
    if selected[i] then
      return tbl
    end

    for j, _ in pairs(selected) do
      selected[j] = nil
      table.insert(tbl, j)
    end

    selected[i] = true
    table.insert(tbl, i)
  else
    -- Order important; `truthy and nil` doesn't short-circuit.
    selected[i] = not selected[i] and true or nil
    table.insert(tbl, i)
  end

  return tbl
end

---@package
---Convert `fields` to a list of chunks for a line with index `i`.
---
---@param i number
---@param fields string|Field[]
---@param delim string
---@return Chunk[]
function M.ui._chunk(i, fields, delim)
  ---@type Chunk[]
  local chunks = {}
  local col = 0

  if type(fields) == 'string' then
    fields = { { fields, 'Normal' } }
  end

  -- Convert all fields to Highlight-Group-Tuples (see `HlTuple`).
  fields = vim
    .iter(fields)
    :map(
      ---@param f Field
      function(f)
        -- NOTE: this assumes ANY table is a valid tuple
        if type(f) == 'table' then
          return f
        end

        return { f, 'Normal' }
      end
    )
    :filter(
      ---@param f HlTuple
      function(f)
        return f[1]:len() > 0
      end
    )
    :totable()

  -- Store index column as separate chunk.
  table.insert(chunks, {
    text = i,
    line = i - 1,
    start = col,
    end_ = col + tostring(i):len(),
  })
  col = col + tostring(i):len() + delim:len()

  ---Convert all tuples to chunks.
  ---@param f HlTuple
  for _, f in pairs(fields) do
    table.insert(chunks, {
      text = f[1],
      line = i - 1,
      start = col,
      end_ = col + f[1]:len(),
      hl = f[2],
    } --[[@as Chunk]])
    col = col + f[1]:len() + delim:len()
  end

  return chunks
end

---@package
---Join chunks to string separated by `delim`.
---
---@param chunks Chunk[]
---@param delim string?
---@return string
function M.ui._chunk_tostring(chunks, delim)
  return vim
    .iter(chunks)
    :map(
      ---@param c Chunk
      function(c)
        return c.text
      end
    )
    :join(delim or ' ')
end

---Open floating window and allow selection of zero or more items, returning all
---selected items.
---
---The `multi` parameter sets the selection mode. If 'yes', any number of items
---may be selected and returned. This also applies when `multi` is of type
---`number[]`, in which case each element is interpreted as an index to
---pre-select. If the first element is '-1', all items are pre-selected and
---subsequent elements are ignored.
---
---Only one item may be selected if `multi` is either 'no' or 'instant'. In the
---former case, the first item is pre-selected and the selection may be changed
---before confirmation. In the latter case the chosen item is returned
---immediately upon selection. The function will return `T[]` regardless.
---
---Requires 0.10 for `nvim__redraw`.
---
---@generic T
---@param items T[]
---@param mode Mode
---@param format fun(item:T,selected:boolean,index:number):string|Field[] transform item to string representation
---@param config vim.api.keyset.win_config?
---@return T[] selected
function M.ui.pick(items, mode, format, config)
  if M.tbl.isempty(items) then
    return {}
  end

  local delim = ' '
  local nsid = vim.api.nvim_create_namespace('lib_ui')
  local keycode = {
    ['<C-c>'] = 3,
    ['<Esc>'] = 27,
    ['<CR>'] = 13,
  }
  local visual_maps = {
    22 --[[ <C-v> ]],
    86 --[[ v ]],
    118 --[[ <S-v> ]],
  }

  ---Sparse array storing the selection state of each item.
  ---@type table<number, boolean>
  local selected = {}
  ---List of chunks for each item.
  ---@type Chunk[][]
  local chunks = {}
  ---List of screen lines to render.
  ---@type string[]
  local lines = {}

  ---Update a set of lines by re-chunking, stringing, updating buffers and
  ---applying highlights.
  ---
  ---@param bufnr number
  ---@param winnr number
  ---@param indices number[]
  local function rerender(bufnr, winnr, indices)
    for _, i in pairs(indices) do
      chunks[i] =
        M.ui._chunk(i, format(items[i], selected[i] or false, i), delim)
      lines[i] = M.ui._chunk_tostring(chunks[i])
    end

    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
    vim.bo[bufnr].modifiable = false
    M.ui._highlight(bufnr, nsid, vim.fn.flatten(chunks) --[[ @as Chunk[] ]])

    vim.api.nvim_win_set_width(
      winnr,
      math.min(
        M.tbl.max_len({ M.win._parse_title(config), unpack(lines) }),
        M.win._max_width()
      )
    )
  end

  -- Preselect required indices.
  if type(mode) == 'table' and mode[1] == -1 then
    for i = 1, #items do
      selected[i] = true
    end
  elseif type(mode) == 'table' then
    for i = 1, #mode do
      if mode[i] <= #items then
        selected[mode[i]] = true
      end
    end
  elseif mode == 'no' then
    selected[1] = true
  end

  for i = 1, #items do
    local ch = M.ui._chunk(i, format(items[i], selected[i] or false, i), delim)

    table.insert(chunks, ch)
    table.insert(lines, M.ui._chunk_tostring(ch))
  end

  config = config or {}
  config.width = math.min(
    M.tbl.max_len({ M.win._parse_title(config), unpack(lines) }),
    M.win._max_width()
  )

  local data = M.win.open_cursor(lines, true, config)
  M.ui._highlight(data.nbuf, nsid, vim.fn.flatten(chunks) --[[ @as Chunk[] ]])
  M.ui._register_close_events(data.nbuf, data.nwin)

  while true do
    vim.api.nvim__redraw({ flush = true, win = data.nwin, cursor = true })
    -- stylua: ignore
    local c, num =
      vim.fn.getchar() --[[@as integer]],
      nil

    if c == keycode['<C-c>'] then
      selected = {}
      break
    end

    if c == keycode['<Esc>'] then
      break
    end

    if c == keycode['<CR>'] then
      rerender(
        data.nbuf,
        data.nwin,
        M.ui._select(data.nwin, mode, vim.fn.line('.'), selected)
      )

      if mode == 'instant' then
        break
      else
        goto continue
      end
    end

    if vim.tbl_contains(visual_maps, c) then
      goto continue
    end

    num = tonumber(vim.fn.nr2char(c))
    if num and num > 0 then
      if num <= #items then
        rerender(
          data.nbuf,
          data.nwin,
          M.ui._select(data.nwin, mode, num, selected)
        )

        -- Terminate after first valid number instead of selecting again.
        if mode == 'instant' then
          break
        end
      end

      goto continue
    end

    -- other key -- handle as normal
    --
    -- FIX: does not handle multi-character commands. Could be implmented by
    -- storing queued keys as typeahead-string and checking whether string is a
    -- valid command-sequence. See `maplist` | `maparg`.
    vim.fn.feedkeys(vim.fn.nr2char(c))
    vim.fn.feedkeys('', 'x')

    ::continue::
  end

  M.win.close(data.nwin)

  local tbl = {}
  for i, _ in pairs(selected) do
    table.insert(tbl, items[i])
  end
  return tbl
end

---------------------------------------------------------------------------- win

---Maximum window width when `relative` is 'editor'.
M.win._MAXSIZE = 0.8
---Reuired offset to center floating window when `relative` is 'editor'.
M.win._OFFSET = (1 - M.win._MAXSIZE) / 2

---@package
---Extract window title string from `nvim_open_win()`'s `config` table.
---
---@param config vim.api.keyset.win_config?
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

---@package
---Calculate maximum window width, maintaining desired padding.
---
---@return integer
function M.win._max_width()
  return math.floor(vim.o.columns * M.win._MAXSIZE) - 2
end

---@package
---Calculate maximum window height, maintaining desired padding.
---
---@return integer
function M.win._max_height()
  return math.floor(vim.o.lines * M.win._MAXSIZE)
end

---@package
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

---@package
---Calculate window height, respecting wrapped lines and `showbreak`-offset.
---
---@param data number|string[] buffer | buffer contents
---@return integer
function M.win._height(data)
  if type(data) == 'number' then
    return M.win._max_height()
  end

  -- FIX: should account for cursor offset (getpos('.')[3]-1)
  -- issue: we don't know if the window will be offset to the left because of
  -- its width
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
---@param config vim.api.keyset.win_config?
---@return WinData
function M.win.open(lines, enter, config)
  ---@type WinData
  ---@diagnostic disable-next-line: missing-fields
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

  config = vim.tbl_extend('keep', config or {}, {
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

  data.config = vim.api.nvim_win_get_config(data.nwin)

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
---@param config vim.api.keyset.win_config?
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
---@param config vim.api.keyset.win_config?
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

---@package
---Disable keymaps to enter visual mode in buffer `bufnr`.
---
---@param bufnr number
function M.key._disable_visual_keymaps(bufnr)
  for _, lhs in pairs({ 'v', 'V', '<C-v>' }) do
    M.key.nnmap(lhs, '', { buffer = bufnr })
  end
end

---@package
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

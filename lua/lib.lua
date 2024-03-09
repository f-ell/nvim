local M = {
  cmd = {},
  fs = {},
  io = {},
  key = {},
  lsp = {},
  str = {},
  tbl = {},
  win = {},
}

---------------------------------------------------------------------------- cmd

---Register buffer-local autocommand on <events>.
---
---@param events string|string[]
---@param buffer number
---@param cb string|function
M.cmd.event = function(events, buffer, cb)
  vim.defer_fn(function()
    vim.api.nvim_create_autocmd(events, {
      buffer = buffer,
      nested = true,
      callback = type(cb) == 'string' and cb or function(tbl)
        cb(tbl)
      end,
    })
  end, 0)
end

----------------------------------------------------------------------------- fs

---trailing slash!
M.fs.__dir = vim.fn.stdpath('run') .. '/nvim.user/'

---@param name string
---@return string filename
M.fs.__unique = function(name)
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

---linux only - not portable!
M.fs.__pid = (function()
  for ln in io.lines('/proc/self/status') do
    local match = ln:match('^Pid:.-(%d+)$')
    if match then
      return match
    end
  end
end)()

---Create directory for temporary user files.
M.fs.mktmpdir = function()
  if vim.loop.fs_stat(M.fs.__dir) then
    return
  end

  assert(vim.loop.fs_mkdir(M.fs.__dir, 448), "couldn't create " .. M.fs.__dir)
end

---Write to temporary file.
---
---@param buffer number
---@param data string[]
---@param remove boolean register delete autocommand
---@param name string? basename of the file to write or uniquely generated name
---@return string filename
M.fs.writetmpfile = function(buffer, data, remove, name)
  if not vim.loop.fs_stat(M.fs.__dir) then
    M.fs.mktmpdir()
  end

  local file = M.fs.__dir .. (name and name or M.fs.__pid .. '-' .. buffer)
  M.io.write(name and file or M.fs.__unique(file), data)

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

---@param file string|file* name or handle
---@param mode string
---@return file*|nil filehandle
M.io.__open = function(file, mode)
  if type(file) == 'string' then
    return io.open(file, mode) --[[@as file*]]
  else
    return file
  end
end

---Read file.
---
---@param file string|file* closed automatically
---@param chop boolean? remove trailing newline
---@return string content
M.io.read = function(file, chop)
  local fh = M.io.__open(file, 'r')
  if fh == nil then
    return ''
  end

  local str = fh:read('*a')
  fh:close()
  return chop and str:sub(0, str:len() - 1) or str
end

---Read file (i.e. lines) to consecutive table indices.
---
---@param file string|file* closed automatically
---@return string[] content
M.io.tbl_read = function(file)
  local fh = M.io.__open(file, 'r')
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

---Write <data> to file.
---
---@param file string|file* closed automatically
---@param data string[]
---@param mode 'w'|'w+'|'wb'|'w+b'? defaults to w+
M.io.write = function(file, data, mode)
  if mode and not vim.tbl_contains({ 'w', 'w+', 'wb', 'w+b' }, mode) then
    error('illegal mode - ' .. mode)
  end

  local fh = M.io.__open(file, mode or 'w+')
  assert(fh ~= nil, ('Failed to write `%s`'):format(file))

  fh:write(table.concat(data, '\n') .. '\n')
  fh:flush()
  fh:close()
end

---------------------------------------------------------------------------- lsp

---@class LspClient
---@field id number
---@field name string
---@field rpc table
---@field offset_encoding string
---@field handlers table
---@field requests table
---@field config table
---@field server_capabilities table
---@field request fun(method:string,params:table,handler:fun()?,bufnr:number)
---@field request_sync fun(method:string,params:table,timeout_ms:number,bufnr:number)
---@field notify fun(method:string,params:table)
---@field stop fun(force:boolean?)
---@field is_stopped fun():boolean
---@field on_attach fun(client:LspClient,bufnr:number)

---@class LspResponse
---@field [any] any

---@class (exact) EnrichedLspResponse
---@field id number
---@field name string
---@field result LspResponse

---@class WorkspaceEdit: LspResponse

---@class TextDocumentPositionParams
---@field [any] any

---Apply a workspace edit.
---
---@param response EnrichedLspResponse
M.lsp.apply_edit = function(response)
  if response.result.edit then
    vim.lsp.util.apply_workspace_edit(
      response.result.edit,
      vim.lsp.get_client_by_id(response.id).offset_encoding
    )
  end
  if response.result.action and type(response.result.action) == 'function' then
    response.result.action()
  end
end

---Get all lsp clients with capability "<cap> .. 'Provider'" attached to the
---buffer.
---
---@param capabilities string|string[]
---@param filter (fun(client:LspClient):boolean)? determines whether a client is returned
---@return LspClient[] clients matching lsp clients
M.lsp.clients_by_cap = function(capabilities, filter)
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
    vim.notify('No client(s) found', vim.log.levels.dINFO)
  end
  return clients
end

-- TODO: refactor to return err, res
---Get response from all passed-in clients.
---
---@param clients LspClient|LspClient[]
---@param method string
---@param params TextDocumentPositionParams
---@param buffer number
---@param callback fun(res:LspResponse)? called for each response; should handle errors
---@return EnrichedLspResponse[]
M.lsp.request = function(clients, method, params, buffer, callback)
  clients = (type(clients) == 'table' and type(clients[1]) == 'table')
      and clients
    or { clients }
  local responses = {}

  for i = 1, #clients do
    local c = clients[i]
    local dict = c.request_sync(method, params, 500, buffer)

    if callback ~= nil then
      if type(callback) == 'function' then
        callback(dict)
      end
    else
      if M.tbl.is_empty(dict) or M.tbl.is_empty(dict.result) or dict.err then
        goto continue
      end
    end

    if M.tbl.is_empty(dict) then
      goto continue
    end
    if type(dict.result[1]) == 'table' then
      for j = 1, #dict.result do
        table.insert(responses, {
          id = c.id,
          name = c.name,
          result = dict.result[j],
        })
      end
    else
      table.insert(responses, {
        id = c.id,
        name = c.name,
        result = dict.result,
      })
    end
    ::continue::
  end

  if #responses == 0 then
    vim.notify('No results found', vim.log.levels.INFO)
  end
  return responses
end

---------------------------------------------------------------------------- tbl

---Perform recursive concatenation of nested array-like tables.
---
---@param tbl number|string|table<string, number, table<string, number>>
---@return string
M.tbl.deep_concat = function(tbl, sep)
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

---@param tbl string[]
---@return integer # length of longest entry
M.tbl.max_len = function(tbl)
  local max = 0
  for i = 1, #tbl do
    local len = vim.fn.strdisplaywidth(tbl[i])
    if len > max then
      max = len
    end
  end
  return max
end

---@param tbl table|nil
---@return boolean # table is empty
M.tbl.is_empty = function(tbl)
  return tbl == nil or (type(tbl) == 'table' and next(tbl) == nil)
end

---------------------------------------------------------------------------- win

---@class (exact) WinData
---@field obuf number buffer number of previously active buffer
---@field owin number window number of previously active window
---@field nbuf number buffer number of newly opened buffer
---@field nwin number window number of newly opened window
---@field width integer
---@field height integer
---@field [any] any

---window width when <relative> is <editor>
M.win.__EW = 0.7
---window width when <relative> is <cursor>
M.win.__CW = 0.8

---@param config table?
---@return string
M.win.__parse_title = function(config)
  if not config then
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

---@return integer # maximum window height; respects <cmdheight>
M.win.__max_height = function()
  return vim.api.nvim_win_get_height(0) - vim.o.cmdheight
end

---@return integer # actual window height
M.win.__height = function(data)
  if type(data) == 'number' then
    return math.floor(vim.o.lines * M.win.__EW)
  end

  local _mw = M.win.__max_width()
  if M.tbl.max_len(data) < _mw then
    return math.min(#data, M.win.__max_height())
  end

  local h, sb = 0, vim.fn.strdisplaywidth(vim.o.showbreak)
  for _, line in pairs(data) do
    h = h + 1
    local ln = vim.fn.strdisplaywidth(line)

    -- first wrap
    if ln > _mw then
      ln = ln - _mw
      h = h + 1
    end
    -- subsequent wraps
    while ln > _mw do
      ln = ln - _mw + sb
      h = h + 1
    end
  end
  return math.min(h, M.win.__max_height())
end

---@return integer # maximum window width; keeps padding
M.win.__max_width = function()
  return math.floor(vim.o.columns * M.win.__CW) - 2
end

---@return integer # actual window width
M.win.__width = function(data)
  return type(data) == 'number' and math.floor(vim.o.columns * M.win.__EW)
    or math.min(M.tbl.max_len(data), M.win.__max_width())
end

---@return number # required vertical offset to center window
M.win.__voffset = function()
  local o = math.floor(-vim.o.cmdheight / 2)
  local s = vim.o.laststatus
  local t = vim.o.showtabline
  if s > 1 or s == 1 and #vim.api.nvim_tabpage_list_wins(0) > 1 then
    o = o - 1
  end
  if t > 1 or t == 1 and #vim.api.nvim_list_tabpages() > 1 then
    o = o + 1
  end
  return o
end

---@return 'NW'|'SW',0|1 # window anchor and required curosr offset
M.win.anchor_offset = function()
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
M.win.close = function(window, base, pos)
  if not window or not vim.api.nvim_win_is_valid(window) then
    return
  end
  vim.api.nvim_win_close(window, true)
  if base then
    vim.api.nvim_win_set_cursor(base, pos or { 1, 0 })
  end
end

---@param window number
---@return boolean # window is current window and valid
M.win.is_cur_valid = function(window)
  return (
    vim.api.nvim_get_current_win() == window
    and vim.api.nvim_win_is_valid(window)
  )
end

---Open floating window.
---
---@param lines number|string[] buffer number or line-array
---@param enter boolean
---@param config table? config passed to `nvim_open_win`
---@return WinData
M.win.open = function(lines, enter, config)
  ---@type WinData
  local data = {
    obuf = vim.api.nvim_get_current_buf(),
    owin = vim.api.nvim_get_current_win(),
    nbuf = -1,
    nwin = -1,
    height = M.win.__height(lines),
    width = M.win.__width(
      type(lines) == 'number' and lines
        -- if title is present, ensure that it's not cut off
        ---@diagnostic disable-next-line: param-type-mismatch
        or { M.win.__parse_title(config), unpack(lines) }
    ),
  }

  ---@diagnostic disable-next-line: redefined-local
  local config = vim.tbl_extend('keep', config or {}, {
    relative = type(lines) == 'table' and 'cursor' or 'editor',
    anchor = 'NW',
    row = 1,
    col = type(lines) == 'table' and -1
      or math.floor((vim.o.columns * (1 - M.win.__EW)) / 2),
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

---Wraps win.open(), with default position centered relative to editor.
---
---@param lines number|string[] buffer number or line array
---@param enter boolean
---@param config table? config passed to `nvim_open_win`
---@return WinData
M.win.open_center = function(lines, enter, config)
  local conf = vim.tbl_extend('keep', config or {}, {
    relative = 'editor',
    anchor = 'NW',
    row = math.floor((vim.o.lines * (1 - M.win.__EW)) / 2) + M.win.__voffset(),
    col = math.floor((vim.o.columns * (1 - M.win.__EW)) / 2),
  })
  return M.win.open(lines, enter, conf)
end

---Wraps win.open(), with default position at cursor.
---Sets `style = 'minimal'` by default.
---
---@param lines number|string[] buffer number or line array
---@param enter boolean
---@param config table? config passed to `nvim_open_win`
---@return WinData
M.win.open_cursor = function(lines, enter, config)
  local anchor, row = M.win.anchor_offset()
  local conf = vim.tbl_extend('keep', config or {}, {
    relative = 'cursor',
    anchor = anchor,
    row = row,
    col = -1,
    style = 'minimal',
  })
  return M.win.open(lines, enter, conf)
end

---------------------------------------------------------------------------- key

M.key.__map = function(mode, map_opts)
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

M.key.inmap = M.key.__map('i')
M.key.nnmap = M.key.__map('n')
M.key.vnmap = M.key.__map('v')
M.key.cnmap = M.key.__map('c')
M.key.tnmap = M.key.__map('t')

---Set map for one or more modes.
---
---@param modes string|string[]
---@param lhs string
---@param rhs string|function
---@param opts table?
M.key.modemap = function(modes, lhs, rhs, opts)
  opts = vim.tbl_extend('force', { noremap = true }, opts or {})
  vim.keymap.set(modes, lhs, rhs, opts)
end

---Delete map for one or more modes.
---
---@param modes string|string[]
---@param lhs string
---@param opts table?
M.key.unmap = function(modes, lhs, opts)
  vim.keymap.del(modes, lhs, opts or {})
end

return M

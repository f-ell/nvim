---Definition for a `[text, highlight]`-tuple.
---@alias HlTuple [string, string]
---
---Selection mode for UI picker.
---@alias lib.ui.Mode 'yes'|'no'|'instant'|number[]
---
---A chunk associates a string of text with a specific highlight group, to be
---placed at a specific location inside of an arbitrary buffer.
---@class (exact) lib.ui.Chunk
---@field text string
---@field line number
---@field start number
---@field end_ number
---@field hl string?

---@class lib.UI
local UI = {
  ---@package
  _cmd = require('lib.cmd'),
  ---@package
  _key = require('lib.key'),
  ---@package
  _tbl = require('lib.tbl'),
  ---@package
  _win = require('lib.win'),
}

---@package
---Register events to automatically close window `winnr`.
---
---@param bufnr number
---@param winnr number
function UI:_register_close_events(bufnr, winnr)
  self._cmd.register({ 'WinLeave', 'QuitPre' }, bufnr, function()
    self._win:close(winnr)
  end)

  self._key.nnmap('<C-c>', function()
    self._win:close(winnr)
  end, { buffer = bufnr })
end

---@package
---Apply highlights for the given chunks in the given buffer.
---
---@param bufnr number
---@param nsid number
---@param chunks lib.ui.Chunk[]
function UI._highlight(bufnr, nsid, chunks)
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
---@param mode lib.ui.Mode
---@param i number @0-based cursor line index.
---@param selected boolean[] @Sparse array for selected item indices. Updated in place!
---@return number[] @The indices of all items whose selection has changed.
function UI._select(winnr, mode, i, selected)
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
---Convert `fields` to a list of chunks.
---
---@param i number @Line index to associate with the generated chunk.
---@param fields string|string[]|HlTuple[]
---@param delim string
---@return lib.ui.Chunk[]
function UI._chunk(i, fields, delim)
  ---@type lib.ui.Chunk[]
  local chunks = {}
  local col = 0

  if type(fields) == 'string' then
    fields = { { fields, 'Normal' } }
  end

  -- Convert all fields to Highlight-Group-Tuples (see `HlTuple`).
  fields = vim
    .iter(fields)
    :map(
      ---@param f string|HlTuple
      function(f)
        if type(f) == 'table' then
          assert(
            #f == 2 and type(f[1]) == 'string' and type(f[2]) == 'string',
            'invalid highlight tuple'
          )
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
    } --[[@as lib.ui.Chunk]])
    col = col + f[1]:len() + delim:len()
  end

  return chunks
end

---@package
---Join chunks to string separated by `delim`.
---
---@param chunks lib.ui.Chunk[]
---@param delim string?
---@return string
function UI._chunk_tostring(chunks, delim)
  return vim
    .iter(chunks)
    :map(
      ---@param c lib.ui.Chunk
      function(c)
        return c.text
      end
    )
    :join(delim or ' ')
end

---Open floating window and allow selection of zero or more items, returning all
---selected items.
---
---The `mode` parameter sets the selection mode. If 'yes', any number of items
---may be selected and returned. This also applies when `mode` is of type
---`number[]`, in which case each element is interpreted as an index to
---pre-select. If the first element is '-1', all items are pre-selected and
---subsequent elements are ignored.
---
---Only one item may be selected if `mode` is either 'no' or 'instant'. In the
---former case, the first item is pre-selected and the selection may be changed
---before confirmation. In the latter case the chosen item is returned
---immediately upon selection. The function will return `T[]` regardless.
---
---Requires 0.10 for `nvim__redraw`.
---
---@generic T
---@param items T[]
---@param mode lib.ui.Mode
---@param format fun(item:T,selected:boolean,index:number):string|string[]|HlTuple[] @Transform item to string representation.
---@param config vim.api.keyset.win_config?
---@param render fun(winnr:number,bufnr:number,nsid:number)? @Hook invoked on each draw to perform additional logic.
---@return T[] selected
function UI:pick(items, mode, format, config, render)
  if table.isempty(items) then
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
  ---@type lib.ui.Chunk[][]
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
        self._chunk(i, format(items[i], selected[i] or false, i), delim)
      lines[i] = self._chunk_tostring(chunks[i])
    end

    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
    vim.bo[bufnr].modifiable = false
    self._highlight(
      bufnr,
      nsid,
      vim.fn.flatten(chunks) --[[ @as lib.ui.Chunk[] ]]
    )

    vim.api.nvim_win_set_width(
      winnr,
      math.min(
        self._tbl.max_len({ self._win.parse_title(config), unpack(lines) }),
        self._win.max_width()
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
    local ch = self._chunk(i, format(items[i], selected[i] or false, i), delim)

    table.insert(chunks, ch)
    table.insert(lines, self._chunk_tostring(ch))
  end

  config = config or {}
  config.width = math.min(
    self._tbl.max_len({ self._win.parse_title(config), unpack(lines) }),
    self._win.max_width()
  )

  local data = self._win:open_cursor(lines, true, config)
  self._highlight(
    data.nbuf,
    nsid,
    vim.fn.flatten(chunks) --[[ @as lib.ui.Chunk[] ]]
  )
  self:_register_close_events(data.nbuf, data.nwin)

  while true do
    if render then
      render(data.nwin, data.nbuf, nsid)
    end

    vim.api.nvim__redraw({ flush = true, buf = data.nbuf, cursor = true })
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
        self._select(data.nwin, mode, vim.fn.line('.'), selected)
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
          self._select(data.nwin, mode, num, selected)
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
    -- TODO: index into `nvim_get_keymap` by `lhs`.
    vim.fn.feedkeys(vim.fn.nr2char(c))
    vim.fn.feedkeys('', 'x')

    ::continue::
  end

  self._win:close(data.nwin)

  local tbl = {}
  for i, _ in pairs(selected) do
    table.insert(tbl, items[i])
  end
  return tbl
end

return UI

-- PERF: register running jobs and deregister in on_exit to prevent duplication
local M = {
  init = function(self)
    for i = 1, #self._components do
      self.register_callbacks(self._components[i])
    end

    vim.api.nvim_create_autocmd(self._buf_events, {
      callback = function()
        self._realpath = vim.uv.fs_realpath(vim.fn.expand('%:p'))
      end,
    })

    vim.api.nvim_create_autocmd('FocusGained', {
      callback = function()
        vim.defer_fn(function()
          vim.cmd('redrawstatus')
        end, 0)
      end,
    })
  end,

  render = function(self)
    local tbl = setmetatable({}, { __index = table })

    for i = 1, #self._components do
      if
        self._components[i].enabled == nil
        or self._components[i].enabled == true
      then
        tbl:insert(
          type(self._components[i].get) == 'function'
              and self._components[i]:get()
            or self._components[i].get
        )
      end
    end

    return (' %s%%< '):format(vim.fn.trim(tbl:concat(' ')))
  end,

  ---Components may contain additional fields used to keep state or perform
  ---arbitrary calculations.
  ---
  ---Each component's `get` field is evaluated on every redraw - expensive
  ---calculations should be offloaded to functions executed on events.
  ---
  ---@vararg Component
  add_component = function(self, ...)
    local args = { ... }

    for i = 1, #args do
      if args[i] == nil then
        goto continue
      end

      self._components:insert(args[i])
      if args[i].init then
        args[i]:init()
      end
      self.register_callbacks(args[i])

      ::continue::
    end
  end,

  ---@param component Component
  register_callbacks = function(component)
    if not component.events or component.enabled == false then
      return
    end

    if type(component.events) == 'function' then
      component:events()
    else
      for i = 1, #component.events do
        vim.api.nvim_create_autocmd(component.events[i][1], {
          callback = function(tbl)
            component.events[i][2](component, tbl)
          end,
          nested = true,
        })
      end
    end
  end,

  ---@type string
  _realpath = nil,
  _buf_events = {
    'BufNewFile',
    'BufEnter',
    'BufFilePost',
    'BufWritePost',
    'WinClosed',
    'FocusGained',
    'FileChangedShellPost',
  },
  ---@type Component[]
  _components = setmetatable({}, { __index = table }),
}

---@type Component
local mode = {
  meta = {
    mode = 'N',
  },
  events = {
    {
      'ModeChanged',
      function(self)
        local m = vim.api.nvim_get_mode().mode
        if m == '' then
          m = 'v'
        end
        self.meta.mode = m:sub(0, 1):upper()
      end,
    },
  },
  get = function(self)
    return table.concat({
      ('%%#mode%s#'):format(self.meta.mode),
      self.meta.mode,
      '%#StatusLine#',
    })
  end,
}

---@type Component
local buffer = {
  meta = {
    name = nil,
  },
  events = {
    {
      M._buf_events,
      function(self)
        local name = vim.fn.bufname()
        name = name == '' and '[null]' or (name:match('([^/]-/?)$') or '_ERR')

        local maxlen = 24
        if name:len() > maxlen then
          local fillchars = '...'

          local i = name:len() - (name:reverse():find('%.') or 0)
          local ext = i and name:sub(i) or ''
          local offset = ext:len() > 0 and 2 + ext:len() or 4
          name = name
            :sub(0, maxlen - (offset + fillchars:len()))
            :gsub('%%', '%%%%') .. fillchars .. name
            :sub(-offset)
            :gsub('%%', '%%%%')
        end

        self.meta.name = name
      end,
    },
  },
  get = function(self)
    return table.concat({
      '%#StatusLine#',
      vim.bo.modified and '+ ' or '- ',
      self.meta.name,
      ' ',
      vim.bo.readonly and '%#StatusLineReadonly#' or '',
      '(%n)',
      '%#StatusLine#',
    })
  end,
}

---@type Component
local git = {
  meta = {
    relative_name = nil,
    root = {
      global = nil,
      _local = nil,
    },
    tracked = false,
    head = 'HEAD',
    hstate = nil,
    diff = {
      unmerged = true,
      add = 0,
      cha = 0,
      del = 0,
    },
  },
  events = {
    {
      M._buf_events,
      function(self)
        if not self:_root() then
          return
        end

        self:_head()
        self.meta.diff = {
          add = 0,
          cha = 0,
          del = 0,
        }
        if not M._realpath then
          return
        end

        self.meta.relative_name = './'
          .. M._realpath:sub(self.meta.root._local:len() + 1)
        self:_tracked()

        if not self.meta.tracked then
          return
        end

        self:_update_headstate()
        self:_diff()
      end,
    },
    {
      'User',
      function(self, args)
        if
          not (
            self:_root()
            and vim.startswith(args.match, 'GitSigns')
            and M._realpath
          )
        then
          return
        end

        -- safe to proceed w/o further checks - the event is related to git
        self:_head()
        self:_tracked()

        if not self.meta.tracked then
          return
        end

        self:_update_headstate()
        self:_diff()
        vim.cmd('redrawstatus')
      end,
    },
  },
  get = function(self)
    if not self.meta.root.global then
      return ''
    end

    local diff = ''
    if not self.meta.tracked then
      diff = '%#GitZero#untracked'
    elseif self.meta.diff.unmerged then
      diff = '%#GitDel#unmerged'
    else
      local hl = {
        '%#Git' .. (self.meta.diff.add == 0 and 'Zero' or 'Add') .. '#',
        '%#Git' .. (self.meta.diff.cha == 0 and 'Zero' or 'Cha') .. '#',
        '%#Git' .. (self.meta.diff.del == 0 and 'Zero' or 'Del') .. '#',
      }
      diff = table.concat({
        hl[1] .. '+' .. self.meta.diff.add,
        hl[2] .. '~' .. self.meta.diff.cha,
        hl[3] .. '-' .. self.meta.diff.del,
      }, ' ')
    end

    return table.concat({
      '%#Git# ' .. self.meta.head,
      ' ',
      diff,
      '%#StatusLine#',
    })
  end,
  _root = function(self)
    local path = vim.fs.find(
      '.git',
      { upward = true, path = vim.fs.dirname(M._realpath or './') }
    )[1]
    local stat = vim.uv.fs_stat(path or '')

    self.meta.root = {
      global = stat and (stat.type == 'file' and L.io
        .read(path, true)
        :match('^gitdir: (.*)$') or path) or nil,
      _local = path ~= nil and path:gsub('%.git$', '') or nil,
    }

    return self.meta.root.global ~= nil
  end,
  _tracked = function(self)
    local id = vim.fn.jobstart({
      'git',
      'ls-files',
      '--error-unmatch',
      self.meta.relative_name,
    }, {
      cwd = self.meta.root._local,
      stdout_buffered = true,
      on_stdout = function(_, data, _)
        self.meta.tracked = data[1] ~= ''
      end,
    })
    vim.fn.jobwait({ id }, 100)
  end,
  _head = function(self)
    local content = L.io.read(self.meta.root.global .. '/HEAD', true)
    if content == '' then
      return
    end

    local head = content:match('^ref: refs/heads/(.+)$')

    if not head then
      local id = vim.fn.jobstart({
        'git',
        'describe',
        '--tags',
        '--exact-match',
        '@',
      }, {
        cwd = self.meta.root._local,
        stdout_buffered = true,
        on_stdout = function(_, data, _)
          head = data[1] ~= '' and 't:' .. data[1] or content:sub(1, 8)
        end,
      })
      vim.fn.jobwait({ id }, 100)
    end

    self.meta.head = head
  end,
  _update_headstate = function(self)
    local id = vim.fn.jobstart({
      'git',
      'cat-file',
      'blob',
      ':' .. self.meta.relative_name,
    }, {
      cwd = self.meta.root._local,
      stdout_buffered = true,
      on_stdout = function(_, data, _)
        self.meta.hstate = { unpack(data, 1, #data - 1) }
      end,
    })
    vim.fn.jobwait({ id }, 100)
  end,
  _diff = function(self)
    local diff = vim.diff(
      table.concat(self.meta.hstate, '\n'),
      table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'),
      ---@diagnostic disable-next-line: missing-fields
      {
        result_type = 'unified',
      }
    ) --[[@as string]]

    self.meta.diff = {
      unmerged = false,
      add = 0,
      cha = 0,
      del = 0,
    }

    local it = vim.iter(vim.split(diff, '\n'))

    local data = it:filter(function(d)
      return d:sub(0, 2) == '@@'
    end):totable()

    -- order important - `any` consumes iterator
    if it:any(function(d)
      return d:sub(0, 3) == '@@@'
    end) then
      self.meta.diff.unmerged = true
      return
    end

    for i = 1, #data do
      local d = { data[i]:match('^@@ %-%d+,?(%d*) %+%d+,?(%d*) @@') }
      if d[1] == '' then
        d[1] = '1'
      end
      if d[2] == '' then
        d[2] = '1'
      end

      d = vim.tbl_map(function(v)
        return tonumber(v)
      end, d)

      if d[1] == 0 then
        self.meta.diff.add = self.meta.diff.add + d[2]
      elseif d[2] == 0 then
        self.meta.diff.del = self.meta.diff.del + d[1]
      else
        self.meta.diff.cha = self.meta.diff.cha + math.min(d[1], d[2])

        if d[2] > d[1] then
          self.meta.diff.add = self.meta.diff.add + (d[2] - d[1])
        elseif d[2] < d[1] then
          self.meta.diff.del = self.meta.diff.del + (d[1] - d[2])
        end
      end
    end
  end,
}

---@type Component
local lsp = {
  meta = {
    ---@type vim.diagnostic.Opts.Signs
    signs = nil,
    clients = {},
    diagnostics = {
      count = { 0, 0, 0, 0 },
      string = '',
    },
  },
  events = {
    {
      { 'LspAttach', 'LspDetach' },
      function()
        vim.defer_fn(function()
          vim.cmd('redrawstatus')
        end, 0)
      end,
    },
    {
      { 'LspAttach', 'LspDetach', 'BufEnter', 'BufFilePost', 'WinClosed' },
      function(self)
        -- updated on first LspAttach - signs may not be defined beforehand
        if L.tbl.is_empty(self.meta.signs) then
          self.meta.signs = vim.diagnostic.config().signs --[[@as vim.diagnostic.Opts.Signs]]
        end

        self.meta.clients = vim.tbl_map(function(v)
          return v.name
        end, vim.lsp.get_clients({ bufnr = 0 }))
      end,
    },
    {
      { 'BufEnter', 'DiagnosticChanged' },
      function(self)
        if L.tbl.is_empty(self.meta.signs) then
          return
        end

        self.meta.diagnostics = {
          count = { 0, 0, 0, 0 },
          string = '',
        }

        local diagnostics = vim.diagnostic.get(0)
        for i = 1, #diagnostics do
          self.meta.diagnostics.count[diagnostics[i].severity] = self.meta.diagnostics.count[diagnostics[i].severity]
            + 1
        end

        local part = {}
        for i = 1, #self.meta.diagnostics.count do
          if self.meta.diagnostics.count[i] ~= 0 then
            part[#part + 1] = ('%%#%s#%s'):format(
              self.meta.signs.numhl[i],
              self.meta.signs.text[i]
            )
          end
        end

        self.meta.diagnostics.string = table.concat(part, ' ')
        vim.cmd('redrawstatus')
      end,
    },
  },
  get = function(self)
    if #self.meta.clients == 0 then
      return ''
    end

    return table.concat({
      #self.meta.diagnostics.string == 0 and '' or self.meta.diagnostics.string,
      '%#StatusLineLspinfo#',
      vim.o.columns < 100 and ''
        or (' %%@v:lua.user_sl_lsp@[%s client%s]%%X'):format(
          #self.meta.clients,
          #self.meta.clients > 1 and 's' or ''
        ),
      ' %#StatusLine#',
    })
  end,
}

---@type Component
local search = {
  meta = {
    search = {
      current = 0,
      exact_match = 0,
      total = '?',
      incomplete = 0,
    },
  },
  get = function(self)
    local ok, search = pcall(vim.fn.searchcount, { maxcount = 998 })

    if not ok then
      search = self.meta.search
    else
      self.meta.search = search
    end

    if search.exact_match == 0 then
      search.current = 0
    end
    if search.incomplete == 1 then
      search.total = '?'
    end

    return table.concat({
      '%#StatusLineSearch#%#StatusLine#',
      search.current .. '/' .. search.total,
    }, ' ')
  end,
}

---@type Component
local location = { get = '%#StatusLineLocation#%#StatusLine# %l:%v' }

M:init()

M:add_component(mode, buffer, git, { get = '%=%<' }, lsp, search, location)

_G.statusline = function()
  return M:render()
end
_G.user_sl_lsp = function()
  print(table.concat(lsp.meta.clients, ', '))
end
vim.o.laststatus = 3
vim.o.statusline = '%!v:lua.statusline()'

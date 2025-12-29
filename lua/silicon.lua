---@class silicon.Opts
---@field directory string
---@field filename string?
---@field font string? @Defaults to `monospace`.
---@field theme string?
---@field window_controls boolean? @Defaults to `false`.

assert(vim.fn.executable('printf') == 1, 'silicon: `printf` not available')
assert(
  vim.fn.executable('silicon') == 1,
  'silicon: executable not found in $PATH'
)

local M = {
  ---@package
  _colours = {
    '#e67e80',
    '#a7c080',
    '#dbbc7f',
    '#7fbbb3',
    '#d699b6',
    '#83c092',
  },
}

---@param opts silicon.Opts
function M:screenshot(opts)
  assert(
    vim.uv.fs_stat(opts.directory),
    'silicon: failed to stat output directory'
  )

  local start, end_ = vim.fn.getpos('v')[2], vim.fn.getpos('.')[2]
  if start < end_ then
    start, end_ = end_, start
  end

  local ln = vim.api.nvim_buf_get_lines(0, start, end_, true)
  ln = vim
    .iter(ln)
    :map(
      ---@param l string
      function(l)
        return l:gsub('\\', '\\\\')
          :gsub('"', '\\"')
          :gsub('`', '\\`')
          :gsub('!', '\\!')
          :gsub('%$', '\\$')
      end
    )
    :totable()

  opts.filename = opts.filename
    or ('silicon_%s.png'):format(os.date('%Y%m%d-%H%M%S'))
  opts.font = opts.font and ("--font '%s'"):format(opts.font) or ''
  opts.theme = opts.theme and ("--theme '%s'"):format(opts.theme) or ''
  opts.window_controls = opts.window_controls or false

  local args = {
    opts.font,
    opts.theme,
    '--output ' .. opts.directory .. opts.filename,
    '--language ' .. (vim.o.filetype or 'sh'),
    ("--background '%s'"):format(self._colours[math.random(1, #self._colours)]),
    '--shadow-offset-x 4',
    '--shadow-offset-y 4',
    '--shadow-blur-radius 6',
    "--shadow-color '#374247'",
    opts.window_controls and '--no-window-controls' or '',
  }

  local retval = os.execute(
    ('printf \'%%s\' "%s" | silicon %s'):format(
      table.concat(ln, '\n'),
      table.concat(args, ' ')
    )
  )

  assert(retval == 0, 'silicon: failed to execute')
  vim.notify('silicon: saved as ' .. opts.filename, vim.log.levels.INFO)
end

return M

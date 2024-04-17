---@type LspUiModuleRename
---@diagnostic disable-next-line: missing-fields
local M = {}

M._util = {
  signs = vim.fn.filter(vim.fn.sign_getdefined(), function(_, s)
    return vim.startswith(s.name, 'DiagnosticSign')
  end),
}

M.rename = function()
  local params = vim.lsp.util.make_position_params(0)
  params.context = { includeDeclaration = true }

  local err, res = L.lsp.request(
    L.lsp.clients_by_cap('references'),
    'textDocument/references',
    params,
    0
  )

  if err then
    L.lsp.notify_error(err)
    return
  end
  if L.tbl.is_empty(res) then
    vim.notify('No rename results found', vim.log.levels.INFO)
    return
  end

  local ln, col = params.position.line, params.position.character

  local declaration
  for i = 1, #res do
    local s, e = res[i].result.range.start, res[i].result.range['end']
    if s.line == ln and s.character <= col and e.character >= col then
      declaration = res[i]
      break
    end
  end

  -- TODO: normal message
  assert(declaration, 'Could not get declaration for symbol under cursor')

  local s, e = declaration.result.range.start, declaration.result.range['end']
  local cword = declaration
      and vim.api.nvim_buf_get_text(
        0,
        s.line,
        s.character,
        e.line,
        e.character,
        {}
      )[1]
    or ''

  M:_open({
    cword = cword,
    refs = res,
    pos = { s.line, s.character },
    path = 'file://' .. vim.fn.expand('%:p'),
  })
end

function M:_preprocess(raw)
  return {
    cword = raw.cword,
    path = raw.path,
    pos = vim.api.nvim_win_get_cursor(0),
    refs = raw.refs,
  }
end

function M:_set_highlights(bufnr, proc)
  local ns_id = vim.api.nvim_create_namespace('LspUi')
  local local_refs = vim.tbl_filter(function(r)
    return r.result.uri == proc.path
  end, proc.refs)

  for i = 1, #local_refs do
    local r = local_refs[i].result.range
    if r then
      vim.api.nvim_buf_add_highlight(
        bufnr,
        ns_id,
        'Search',
        r.start.line,
        r.start.character,
        r['end'].character
      )
    end
  end
end

function M:_register_float_actions(data)
  local close_win = function()
    local ns_id = vim.api.nvim_create_namespace('LspUi')

    if vim.api.nvim_win_is_valid(data.nwin) then
      vim.cmd('stopinsert')
      vim.api.nvim_win_close(data.nwin, true)
      vim.api.nvim_buf_clear_namespace(data.obuf, ns_id, 0, -1)
      vim.api.nvim_win_set_cursor(data.owin, data.proc.pos)
    end
  end

  L.key.modemap({ 'n', 'i', 'v' }, '<C-c>', function()
    close_win()
  end, { buffer = true })

  L.key.modemap({ 'n', 'i' }, '<CR>', function()
    local new = vim.trim(vim.api.nvim_get_current_line())
    close_win()

    if not (new and #new > 0) or new == data.proc.cword then
      return
    end

    vim.api.nvim_win_set_cursor(data.owin, data.proc.pos)
    vim.lsp.buf.rename(new, {})
    vim.api.nvim_win_set_cursor(
      data.owin,
      { data.proc.pos[1], data.proc.pos[2] + 1 }
    )
  end, { buffer = true })

  L.cmd.event({ 'WinLeave', 'QuitPre' }, data.nbuf, function()
    close_win()
  end)
end

function M:_open(raw)
  local proc = self:_preprocess(raw)

  local len, min, max =
    raw.cword:len(), math.min(vim.o.columns, 18), math.min(vim.o.columns, 60)

  vim.api.nvim_win_set_cursor(0, { raw.pos[1] + 1, raw.pos[2] })
  local data = L.win.open_cursor({ raw.cword }, true, {
    title = {
      { ' ' .. self._util.signs[3].text, self._util.signs[3].texthl },
      { 'Rename ', 'FloatTitle' },
    },
    zindex = 2,
    col = -1,
    width = math.min(len < min and min or len + 1, max),
    noautocmd = true,
  })
  data.proc = proc

  vim.bo[data.nbuf].modifiable = true

  self:_set_highlights(data.obuf, proc)
  self:_register_float_actions(data)
  vim.api.nvim_feedkeys('A', 'n', true)
end

return M

local group = vim.api.nvim_create_augroup('autoexec', { clear = false })

local autoexec = {
  _bufname = 'AutoExec',
  _update_id = nil,
  base = {
    name = nil,
    buf = nil,
    win = nil,
  },
  auto = {
    buf = nil,
    win = nil,
  },
  split = 0,
  cmd = nil,
}

local reset = function()
  -- FIX: only close when window open
  L.win.close(autoexec.auto.win)

  autoexec.base = {
    name = nil,
    buf = nil,
    win = nil,
  }
  autoexec.auto = {
    buf = nil,
    win = nil,
  }
  autoexec.split = 0
  autoexec.cmd = nil

  -- TODO: remove all autocmds except AutoExec
end

local has_win = function(winnr)
  return vim.tbl_contains(vim.api.nvim_list_wins(), winnr)
end

local buf = function()
  autoexec.auto.buf = vim.api.nvim_create_buf(false, true)
  if autoexec.auto.buf == 0 then
    error('autoexec: failed to create buffer')
  end

  vim.api.nvim_buf_set_name(autoexec.auto.buf, autoexec._bufname)
end

local split = function()
  vim.cmd(({ 'sp', 'vsp' })[autoexec.split + 1] .. ' | b' .. autoexec.auto.buf)
  autoexec.auto.win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(autoexec.base.win)
end

local register_cmd_cmd = function()
  vim.api.nvim_buf_create_user_command(0, 'AECmd', function()
    print('register_cmd')
  end, {})
end

local register_cmd_del = function()
  vim.api.nvim_buf_create_user_command(0, 'AEDel', function()
    print('register_del')
  end, {})
end

local register_cmd_show = function()
  vim.api.nvim_buf_create_user_command(0, 'AEShow', function()
    print('register_show')
  end, {})
end

vim.api.nvim_create_user_command('AE', function()
  if autoexec.auto.buf then
    if not has_win(autoexec.auto.buf) then
      vim.api.nvim_open_win(autoexec.auto.buf, false)
      return
    end
    return
  end

  autoexec.base.buf = vim.api.nvim_get_current_buf()
  autoexec.base.win = vim.api.nvim_get_current_win()
  autoexec.base.name = vim.api.nvim_buf_get_name(autoexec.base.buf)

  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufDelete', 'BufWipeout' }, {
    group = group,
    buffer = autoexec.base.buf,
    callback = reset,
  })
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufDelete', 'BufWipeout' }, {
    group = group,
    buffer = autoexec.auto.buf,
    callback = reset,
  })

  -- TODO:
  -- get user input
  -- register cmd on unloading / wiping .base.buf or .auto.buf

  register_cmd_show()
  register_cmd_cmd()
  register_cmd_del()

  buf()
  split()

  autoexec._update_id = vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    buffer = autoexec.base.buf,
    callback = function()
      local set_data = function(_, data, _)
        if not data then
          return
        end
        vim.api.nvim_buf_set_option(autoexec.auto.buf, 'modifiable', true)
        vim.api.nvim_buf_set_lines(autoexec.auto.buf, -1, -1, true, data)
        vim.api.nvim_buf_set_option(autoexec.auto.buf, 'modifiable', false)
      end

      vim.api.nvim_buf_set_option(autoexec.auto.buf, 'modifiable', true)
      vim.api.nvim_buf_set_lines(autoexec.auto.buf, 0, -1, false, {
        autoexec.cmd .. ' output:',
        '',
      })
      vim.api.nvim_buf_set_option(autoexec.auto.buf, 'modifiable', false)

      vim.fn.jobstart(autoexec.cmd, {
        stdout_buffered = true,
        on_stdout = set_data,
        on_stderr = set_data,
      })
    end,
  })
end, {})

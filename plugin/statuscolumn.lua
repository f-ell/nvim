local ffi = require('ffi')
ffi.cdef([[ // via luukvbaal/statuscol.nvim
  typedef struct {} Error;
  typedef struct {} win_T;
  typedef struct { int lnum; int level; } foldinfo_T;
  foldinfo_T fold_info(win_T* wp, int lnum);
  win_T *find_window_by_handle(int Window, Error *err);
]])

local lnum = function()
  if not (vim.o.number or vim.o.relativenumber) then
    return ''
  end

  if vim.v.virtnum ~= 0 then
    return ' '
  end

  if vim.v.relnum == 0 then
    return '%#CursorLineNr#' .. vim.v.lnum .. ' '
  end

  return '%#LineNr#'
    .. (vim.o.relativenumber and vim.v.relnum or vim.v.lnum)
    .. ' '
end

local fold = function()
  local wint =
    ffi.C.find_window_by_handle(vim.g.statusline_winid, ffi.new('Error'))
  local finfo = ffi.C.fold_info(wint, vim.v.lnum)

  if finfo.level == 0 or vim.v.virtnum ~= 0 then
    return ' '
  end

  local l0, l1 = finfo.level, ffi.C.fold_info(wint, vim.v.lnum + 1).level
  local f = vim.api.nvim_win_call(vim.g.statusline_winid, function()
    return vim.opt.fillchars:get()
  end)
  local char = f.foldsep

  if vim.v.lnum == finfo.lnum then
    char = vim.api.nvim_win_call(vim.g.statusline_winid, function()
      return vim.fn.foldclosed(vim.v.lnum)
    end) == -1 and f.foldopen or f.foldclose
  elseif -- fold end or neighbouring fold
    l1 < l0
    or (
      ffi.C.fold_info(wint, vim.v.lnum + 1).lnum == vim.v.lnum + 1
      and l1 <= l0
    )
  then
    char = '└'
  elseif l0 > 1 and vim.v.lnum == finfo.lnum + 1 then
    char = l0
  end

  return '%#FoldColumn#' .. char
end

_G.user_sc = function()
  return (vim.wo.diff and '' or fold() .. ' ') .. '%=' .. lnum() .. '%s'
end

vim.o.numberwidth = 2
vim.o.signcolumn = 'yes:1'
vim.o.statuscolumn = '%!v:lua.user_sc()'

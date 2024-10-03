local ffi = require('ffi')
ffi.cdef([[ // via luukvbaal/statuscol.nvim
  typedef struct {} Error;
  typedef struct {} win_T;
  typedef struct { int lnum; int level; } foldinfo_T;
  foldinfo_T fold_info(win_T* wp, int lnum);
  win_T *find_window_by_handle(int Window, Error *err);
]])

local lnum = function()
  if vim.v.virtnum ~= 0 then
    return ''
  end
  return vim.v.relnum == 0 and '%#CursorLineNr#' .. vim.v.lnum
    or '%#LineNr#' .. vim.v.relnum
end

local fold = function()
  local finfo = ffi.C.fold_info(
    ffi.C.find_window_by_handle(0, ffi.new('Error')),
    vim.v.lnum
  )

  if finfo.level == 0 or vim.v.virtnum ~= 0 then
    return ' '
  end

  local l0, l1 = finfo.level, vim.fn.foldlevel(vim.v.lnum + 1)
  local f = vim.opt.fillchars:get()
  local char = f.foldsep

  if vim.v.lnum == finfo.lnum then
    char = vim.fn.foldclosed(vim.v.lnum) == -1 and f.foldopen or f.foldclose
  elseif -- fold end or neighbouring fold
    l1 < l0
    or (
      ffi.C.fold_info(
          ffi.C.find_window_by_handle(0, ffi.new('Error')),
          vim.v.lnum + 1
        ).lnum
        == vim.v.lnum + 1
      and l1 <= l0
    )
  then
    char = '└'
  end

  return '%#FoldColumn#' .. char
end

_G.user_sc = function()
  return (vim.wo.diff and '' or fold() .. ' ') .. '%=' .. lnum() .. ' %s'
end

vim.o.numberwidth = 2
vim.o.signcolumn = 'yes:1'
vim.o.statuscolumn = '%!v:lua.user_sc()'

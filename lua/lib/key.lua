---@class lib.Key
local Key = {}

---@package
---Create mapping function for the given mode.
---
---@param mode 'i'|'n'|'v'|'c'|'t'
---@param map_opts vim.keymap.set.Opts?
---@return fun(lhs:string,rhs:string|function,opts:vim.keymap.set.Opts?)
function Key._map(mode, map_opts)
  map_opts = map_opts or { noremap = true } --[[@as vim.keymap.set.Opts]]

  ---Wraps vim.keymap.set. The mode is derived from the overarching call.
  ---
  ---@param lhs string
  ---@param rhs string|function
  ---@param opts vim.keymap.set.Opts?
  return function(lhs, rhs, opts)
    opts = vim.tbl_extend('force', map_opts, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

Key.inmap = Key._map('i')
Key.nnmap = Key._map('n')
Key.vnmap = Key._map('v')
Key.cnmap = Key._map('c')
Key.tnmap = Key._map('t')

---Set map for one or more modes.
---
---@param modes string|string[]
---@param lhs string
---@param rhs string|function
---@param opts vim.keymap.set.Opts?
function Key.modemap(modes, lhs, rhs, opts)
  opts = vim.tbl_extend('force', { noremap = true }, opts or {})
  vim.keymap.set(modes, lhs, rhs, opts)
end

---Delete map for one or more modes.
---
---@param modes string|string[]
---@param lhs string
---@param opts vim.keymap.del.Opts?
function Key.unmap(modes, lhs, opts)
  vim.keymap.del(modes, lhs, opts or {})
end

return Key

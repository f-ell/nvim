---Returns `true` if table is empty or `nil`.
---
---@param tbl table?
---@return boolean
function table.isempty(tbl)
  return tbl == nil or type(tbl) == 'table' and vim.tbl_isempty(tbl)
end

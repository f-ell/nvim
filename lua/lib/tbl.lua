---@class lib.Tbl
local Tbl = {}

---Return the display width of the longest item in `tbl`.
---
---@param tbl string[]
---@return integer
function Tbl.max_len(tbl)
  local max = vim
    .iter(ipairs(tbl))
    :filter(
      ---@param k string|number
      function(k, _)
        return type(k) == 'number'
      end
    )
    :fold(
      0,
      ---@param acc number
      ---@param v string
      function(acc, _, v)
        local len = vim.fn.strcharlen(v)
        return len > acc and len or acc
      end
    )

  return max
end

return Tbl

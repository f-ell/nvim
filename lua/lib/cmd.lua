---@class lib.Cmd
local Cmd = {}

---Register buffer-local autocommand on `events`.
---
---@param events string|string[]
---@param bufnr integer
---@param callback string|function
---@return integer
function Cmd.register(events, bufnr, callback)
  local id = -1

  -- TODO: does this need to be deferred?
  vim.defer_fn(function()
    id = vim.api.nvim_create_autocmd(events, {
      buffer = bufnr,
      nested = true,
      callback = type(callback) == 'string' and callback or function(tbl)
        callback(tbl)
      end,
    })
  end, 0)

  return id
end

return Cmd

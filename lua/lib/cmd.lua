---@class lib.Cmd
local Cmd = {}

---Register buffer-local autocommand on `events`.
---
---@param events string|string[]
---@param bufnr number
---@param callback string|function
function Cmd.register(events, bufnr, callback)
  -- TODO: return autocmd ID for removal
  -- TODO: does this need to be deferred?
  vim.defer_fn(function()
    vim.api.nvim_create_autocmd(events, {
      buffer = bufnr,
      nested = true,
      callback = type(callback) == 'string' and callback or function(tbl)
        callback(tbl)
      end,
    })
  end, 0)
end

return Cmd

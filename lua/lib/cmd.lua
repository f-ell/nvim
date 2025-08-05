---@class lib.Cmd
local Cmd = {}

---Register buffer-local autocommand on `events`.
--- TODO: rename
---
---@param events string|string[]
---@param bufnr number
---@param callback string|function
function Cmd.event(events, bufnr, callback)
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

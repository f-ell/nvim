---@meta _

---@alias Request LspResponse[]|table<any,any>

---@class lsp.ui
---@field _open fun(self:lsp.ui,req:Request) @Wrapper for all UI-handling.
---@field _preprocess fun(self:lsp.ui,any...):any @Transform request by extracting relevant or deriving new information.
---@field _set_highlights fun(self:lsp.ui,bufnr:number,any...)?
---@field _register_float_actions fun(self:lsp.ui,data:WinData,any...)? @Register autocommands, buffer-local keymaps, or similar.
---@field _util table<any,any>?

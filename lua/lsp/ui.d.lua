---@meta _

---@alias Raw LspResponse[]|table<any,any>
---@alias Proc table<any, any>

---@class (exact) lsp.ui
---@field _open fun(self:lsp.ui,raw:Raw) @group all logic and open window
---@field _preprocess fun(self:lsp.ui,raw:Raw):Proc @transform raw data and derive required fields
---@field _format fun(self:lsp.ui,proc:Proc):string[] @generate line array to display
---@field _set_highlights fun(self:lsp.ui,bufnr:number,proc:Proc) @set highlights in new window
---@field _register_float_actions fun(self:lsp.ui,data:WinData)? @register autocommands, buffer-local keybinds, or similar
---@field _util table<any,any>?

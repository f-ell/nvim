---@alias Raw EnrichedLspResponse[]|table<any,any>
---@alias Proc table<any, any>

---@class (exact) LspUiModule
---@field _open fun(self:LspUiModule,raw:Raw) @group all logic and open window
---@field _preprocess fun(self:LspUiModule,raw:Raw):Proc @transform raw data and derive required fields
---@field _format fun(self:LspUiModule,proc:Proc):string[] @generate line array to display
---@field _set_highlights fun(self:LspUiModule,bufnr:number,proc:Proc) @set highlights in new window
---@field _register_float_actions fun(self:LspUiModule,data:WinData)? @register autocommands, buffer-local keybinds, or similar
---@field _util table<any,any>?

---@class (exact) LspUiModuleCodeAction:LspUiModule
---@field codeaction fun()

---@class (exact) LspUiModuleDefinition:LspUiModule
---@field peek fun(self:LspUiModule)
---@field open fun(self:LspUiModule)
---@field type fun(self:LspUiModule)

---@class (exact) LspUiModuleDiagnostic:LspUiModule
---@field goto_next fun()
---@field goto_prev fun()
---@field get_line fun()

---@class (exact) LspUiModuleRename:LspUiModule
---@field rename fun()

---@class (exact) LspUiModuleSignatureHelp:LspUiModule
---@field active fun()
---@field available fun()

-- inspired by glepnir's lspsaga: https://github.com/nvimdev/lspsaga.nvim

---@alias Raw EnrichedLspResponse[]|table<any,any>
---@alias Proc table<any, any>

---@class (exact) LspUiModule
---@field _open fun(self:LspUiModule,raw:Raw) @group all logic and open window
---@field _preprocess fun(self:LspUiModule,raw:Raw):Proc @transform raw data and derive required fields
---@field _format fun(self:LspUiModule,proc:Proc):string[] @generate line array to display
---@field _set_highlights fun(self:LspUiModule,bufnr:number,proc:Proc) @set highlights in new window
---@field _register_float_actions fun(self:LspUiModule,data:WinData)? @register autocommands, buffer-local keybinds, or similar
---@field _util table<any,any>?

return {
  cda = require('lsp.ui.code_action'),
  def = require('lsp.ui.definition'),
  dgn = require('lsp.ui.diagnostic'),
  ren = require('lsp.ui.rename'),
  sig = require('lsp.ui.signature_help'),
}

---@meta

---@class RequestError
---@field name string
---@field method string
---@field message string?

---@class RPCError
---@field code number
---@field message string
---@field data table?

---@class RPCResult
---@field [any] any

---@class RPCResponse
---@field err RPCError
---@field result RPCResult

---@class (exact) EnrichedLspResponse
---@field id number
---@field name string
---@field result RPCResult

---@class WorkspaceEdit: RPCResult

---@class TextDocumentPositionParams
---@field [any] any

---@alias LogLevel 0|1|2|3|4|5

--------------------------------------------------------------------------------

---@class (exact) WinData
---@field obuf number buffer number of previously active buffer
---@field owin number window number of previously active window
---@field nbuf number buffer number of newly opened buffer
---@field nwin number window number of newly opened window
---@field width integer
---@field height integer
---@field config vim.api.keyset.win_config
---@field [any] any

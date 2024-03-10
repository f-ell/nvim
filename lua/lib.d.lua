---@meta

---@class LspClient
---@field id number
---@field name string
---@field rpc table
---@field offset_encoding string
---@field handlers table
---@field requests table
---@field config table
---@field server_capabilities table
---@field request fun(method:string,params:table,handler:fun()?,bufnr:number)
---@field request_sync fun(method:string,params:table,timeout_ms:number,bufnr:number)
---@field notify fun(method:string,params:table)
---@field stop fun(force:boolean?)
---@field is_stopped fun():boolean
---@field on_attach fun(client:LspClient,bufnr:number)

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
---@field [any] any

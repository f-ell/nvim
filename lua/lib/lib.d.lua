---@meta _

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

---@class (exact) LspResponse
---@field id number
---@field name string
---@field result RPCResult

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

--------------------------------------------------------------------------------

---@alias Mode 'yes'|'no'|'instant'|number[]

---Definition for a `[text, highlight]`-tuple.
---@alias HlTuple {[1]: string, [2]:string}
---@alias Field string|HlTuple

---A chunk associates a string of text with a specific highlight group, to be
---placed at a specific location inside of an arbitrary buffer.
---@class Chunk
---@field text string
---@field line number
---@field start number
---@field end_ number
---@field hl string?

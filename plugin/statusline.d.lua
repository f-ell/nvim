---@meta

---@class Component
---@field name string,
---@field enabled boolean?
---@field init fun(self:self)?
---@field events fun(self:self)|Listener[]?
---@field get string|number|fun(self:self):string
---@field [any] any

---@class Listener
---@field [1] string|string[]
---@field [2] fun(component:Component, tbl: table?)

local M = {
  ---@type table<string, vim.api.keyset.highlight>
  groups = nil,
}

---@package
---Re-evaluate highlight group definitions. This is necessary when the
---underlying colour palette changes, e.g. when `background` is set.
function M:eval()
  self.groups = {
    NeutralFloat = { fg = LEAFLESS.gr[3] },

    -- statusline
    StatusLineReadonly = { fg = LEAFLESS.bright.red },

    modeC = { fg = LEAFLESS.bright.pur },
    modeI = { fg = LEAFLESS.bright.blu },
    modeN = { fg = LEAFLESS.bright.gre },
    modeR = { fg = LEAFLESS.bright.red },
    modeT = { fg = LEAFLESS.bright.ora },
    modeV = { fg = LEAFLESS.bright.yel },

    Git = { fg = '#fca326' },
    GitZero = { link = 'NonText' },
    GitAdd = { fg = LEAFLESS.bright.gre },
    GitCha = { fg = LEAFLESS.bright.blu },
    GitDel = { fg = LEAFLESS.bright.red },

    -- blink
    BlinkCmpLabelDeprecated = { fg = LEAFLESS.gr[3] },
    BlinkCmpMenuSelection = { link = 'PmenuSel' },
    BlinkCmpSource = { link = 'NonText' },

    -- File system / Top-Level organisation: cyan
    -- Top-Level language constructs: yellow
    -- Callables: green
    -- Member values: blue
    -- Enumerations: purple
    -- Variables: blue
    -- Special values: orange
    -- Overarching features: red
    BlinkCmpKindArray = { link = 'BlinkCmpKindVariable' },
    BlinkCmpKindBoolean = { link = 'BlinkCmpKindConstant' },
    BlinkCmpKindClass = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindColor = { fg = LEAFLESS.normal.ora },
    BlinkCmpKindConstant = { fg = LEAFLESS.normal.blu },
    BlinkCmpKindConstructor = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindDefault = { link = 'Normal' },
    BlinkCmpKindEnum = { fg = LEAFLESS.normal.pur },
    BlinkCmpKindEnumMember = { fg = LEAFLESS.normal.pur },
    BlinkCmpKindEvent = { fg = LEAFLESS.normal.ora },
    BlinkCmpKindField = { fg = LEAFLESS.normal.blu },
    BlinkCmpKindFile = { fg = LEAFLESS.normal.cya },
    BlinkCmpKindFolder = { fg = LEAFLESS.normal.cya },
    BlinkCmpKindFunction = { fg = LEAFLESS.normal.gre },
    BlinkCmpKindInterface = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindKey = { link = 'BlinkCmpKindKeyword' },
    BlinkCmpKindKeyword = { fg = LEAFLESS.normal.red },
    BlinkCmpKindMethod = { fg = LEAFLESS.normal.gre },
    BlinkCmpKindModule = { fg = LEAFLESS.normal.cya },
    BlinkCmpKindNamespace = { link = 'BlinkCmpKindModule' },
    BlinkCmpKindNull = { link = 'BlinkCmpKindConstant' },
    BlinkCmpKindNumber = { link = 'BlinkCmpKindValue' },
    BlinkCmpKindObject = { link = 'BlinkCmpKindClass' },
    BlinkCmpKindOperator = { fg = LEAFLESS.normal.red },
    BlinkCmpKindPackage = { link = 'BlinkCmpKindModule' },
    BlinkCmpKindProperty = { fg = LEAFLESS.normal.blu },
    BlinkCmpKindReference = { fg = LEAFLESS.normal.blu },
    BlinkCmpKindSnippet = { fg = LEAFLESS.normal.red },
    BlinkCmpKindString = { link = 'BlinkCmpKindValue' },
    BlinkCmpKindStruct = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindText = { fg = LEAFLESS.normal.cya },
    BlinkCmpKindTypeParameter = { fg = LEAFLESS.normal.red },
    BlinkCmpKindUnit = { fg = LEAFLESS.normal.ora },
    BlinkCmpKindValue = { fg = LEAFLESS.normal.ora },
    BlinkCmpKindVariable = { fg = LEAFLESS.normal.blu },
  }
end

---Update and set highlight group definitions.
function M:set()
  self:eval()

  for name, spec in pairs(self.groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

return M

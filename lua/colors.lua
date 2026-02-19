local M = {
  ---@type table<string, vim.api.keyset.highlight>
  groups = {
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
    GitZero = { fg = LEAFLESS.gr[4] },
    GitAdd = { fg = LEAFLESS.bright.gre },
    GitCha = { fg = LEAFLESS.bright.blu },
    GitDel = { fg = LEAFLESS.bright.red },

    -- tabline
    TabActive = { fg = LEAFLESS.fg[2], bg = LEAFLESS.bg[2], bold = true },
    TabInactive = { fg = LEAFLESS.fg[3], bg = LEAFLESS.bg[3] },

    -- blink
    BlinkCmpLabelDeprecated = { fg = LEAFLESS.gr[3] },
    BlinkCmpMenuSelection = { fg = nil, bg = LEAFLESS.bg[1] },
    BlinkCmpSource = { link = 'NonText' },

    BlinkCmpKindArray = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindBoolean = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindClass = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindColor = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindConstant = { fg = LEAFLESS.normal.blu },
    BlinkCmpKindConstructor = { fg = LEAFLESS.normal.gre },
    BlinkCmpKindDefault = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindEnum = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindEnumMember = { fg = LEAFLESS.normal.pur },
    BlinkCmpKindEvent = { fg = LEAFLESS.normal.ora },
    BlinkCmpKindField = { fg = LEAFLESS.normal.gre },
    BlinkCmpKindFile = { fg = LEAFLESS.normal.gre },
    BlinkCmpKindFolder = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindFunction = { fg = LEAFLESS.normal.gre },
    BlinkCmpKindInterface = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindKey = { fg = LEAFLESS.normal.red },
    BlinkCmpKindKeyword = { fg = LEAFLESS.normal.red },
    BlinkCmpKindMethod = { fg = LEAFLESS.normal.gre },
    BlinkCmpKindModule = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindNamespace = { fg = LEAFLESS.normal.pur },
    BlinkCmpKindNull = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindNumber = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindObject = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindOperator = { fg = LEAFLESS.normal.ora },
    BlinkCmpKindPackage = { fg = LEAFLESS.normal.pur },
    BlinkCmpKindProperty = { fg = LEAFLESS.normal.blu },
    BlinkCmpKindReference = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindSnippet = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindString = { fg = LEAFLESS.normal.aqu },
    BlinkCmpKindStruct = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindText = { link = 'Normal' },
    BlinkCmpKindTypeParameter = { fg = LEAFLESS.normal.yel },
    BlinkCmpKindUnit = { fg = LEAFLESS.normal.pur },
    BlinkCmpKindValue = { fg = LEAFLESS.normal.pur },
    BlinkCmpKindVariable = { fg = LEAFLESS.normal.blu },
  },
}

function M:set()
  for name, spec in pairs(self.groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

return M

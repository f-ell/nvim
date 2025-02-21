local c = {
  _ = '',

  fg = {
    '#e0dbd0',
    '#d5cfc1',
    '#cac3b3',
    '#bfb7a5',
    '#b3aa97',
    '#a79e8a',
  },
  gr = {
    '#a8aeb1',
    '#94999c',
    '#808487',
    '#6d7072',
    '#5a5d5f',
    '#484a4b',
  },
  bg = {
    '#465258',
    '#3c464b',
    '#333b3f',
    '#2a3033',
    '#212628',
    '#191b1d',
  },

  pastel = {
    aqu = '#83c092',
    blu = '#7fbbb3',
    gre = '#a7c080',
    pur = '#d699b6',
    red = '#e67e80',
    yel = '#dbbc7f',
  },
  darkened = {
    aqu = '#4f7459',
    blu = '#4d716d',
    gre = '#65744e',
    pur = '#825d6e',
    red = '#8b4c4e',
    yel = '#85724d',
  },
  vivid = {
    aqu = '#35a77c',
    blu = '#3a94c5',
    gre = '#8da101',
    pur = '#df69ba',
    red = '#f85552',
    yel = '#dfa000',
  },
  misc = { git = '#fca326' },
}

local highlights = {
  ---- builtin ----
  { 'Fg', { fg = c.fg[2] } },
  { 'Normal', { fg = c.fg[2] } },
  { 'NormalNC', { link = 'Normal' } },
  { 'Grey', { fg = c.gr[4] } },
  { 'Comment', { fg = c.gr[4], bold = true } },

  { 'Aqua', { link = 'Fg' } },
  { 'Blue', { link = 'Fg' } },
  { 'Green', { link = 'Fg' } },
  { 'Orange', { link = 'Fg' } },
  { 'Purple', { link = 'Fg' } },
  { 'Red', { link = 'Fg' } },
  { 'Yellow', { link = 'Fg' } },
  { 'AquaItalic', { fg = c.fg[2], bold = true } },
  { 'BlueItalic', { fg = c.fg[2], bold = true } },
  { 'GreenItalic', { fg = c.fg[2], bold = true } },
  { 'OrangeItalic', { fg = c.fg[2], bold = true } },
  { 'PurpleItalic', { fg = c.fg[2], bold = true } },
  { 'RedItalic', { fg = c.fg[2], bold = true } },
  { 'YellowItalic', { fg = c.fg[2], bold = true } },

  { 'Constant', { fg = c.fg[1], bold = true } },
  { 'Identifier', { fg = c.fg[2], bold = true } },
  { 'PreProc', { fg = c.gr[4], bold = true } },
  { 'Special', { link = 'Fg' } },
  { 'Statement', { fg = c.fg[1] } },
  { 'Type', { link = 'Fg' } },

  { 'Boolean', { link = 'Constant' } },
  { 'Character', { link = 'Constant' } },
  { 'Conditional', { link = 'Statement' } },
  { 'Debug', { link = 'Special' } },
  { 'Define', { link = 'PreProc' } },
  { 'Delimiter', { link = 'Special' } },
  { 'Exception', { link = 'Statement' } },
  { 'Float', { link = 'Constant' } },
  { 'Function', { link = 'Identifier' } },
  { 'Include', { link = 'PreProc' } },
  { 'Keyword', { link = 'Statement' } },
  { 'Label', { link = 'Statement' } },
  { 'Macro', { link = 'PreProc' } },
  { 'Number', { link = 'Constant' } },
  { 'Operator', { link = 'Statement' } },
  { 'PreCondit', { link = 'PreProc' } },
  { 'Repeat', { link = 'Statement' } },
  { 'SpecialChar', { link = 'Special' } },
  { 'SpecialComment', { link = 'Special' } },
  { 'StorageClass', { link = 'Type' } },
  { 'String', { link = 'Constant' } },
  { 'Structure', { link = 'Type' } },
  { 'Tag', { link = 'Special' } },
  { 'Typedef', { link = 'Type' } },

  -- diagnostics
  { 'ErrorText', { sp = c.vivid.red, underline = true } },
  { 'WarningText', { sp = c.vivid.yel, underline = true } },
  { 'InfoText', { sp = c.vivid.gre, underline = true } },
  { 'HintText', { sp = c.vivid.blu, underline = true } },

  { 'DiagnosticOk', { fg = c.pastel.pur } },
  { 'DiagnosticUnnecessary', { fg = c.gr[4] } },
  { 'DiagnosticError', { fg = c.pastel.red } },
  { 'DiagnosticWarn', { fg = c.pastel.yel } },
  { 'DiagnosticInfo', { fg = c.pastel.gre } },
  { 'DiagnosticHint', { fg = c.pastel.blu } },
  { 'DiagnosticUnderlineError', { link = 'ErrorText' } },
  { 'DiagnosticUnderlineWarn', { link = 'WarningText' } },
  { 'DiagnosticUnderlineInfo', { link = 'InfoText' } },
  { 'DiagnosticUnderlineHint', { link = 'HintText' } },
  { 'DiagnosticSignError', { link = 'DiagnosticError' } },
  { 'DiagnosticSignWarn', { link = 'DiagnosticWarn' } },
  { 'DiagnosticSignInfo', { link = 'DiagnosticInfo' } },
  { 'DiagnosticSignHint', { link = 'DiagnosticHint' } },

  -- diff
  { 'DiffText', { fg = c.bg[6], bg = c.vivid.blu } },
  { 'DiffAdd', { fg = c.bg[6], bg = c.pastel.gre } },
  { 'DiffChange', { fg = c.bg[6], bg = c.pastel.blu } },
  { 'DiffDelete', { fg = c.bg[6], bg = c.pastel.red } },

  -- float
  { 'NormalFloat', { link = 'Fg' } },
  { 'FloatTitle', { link = 'Fg' } },
  { 'FloatBorder', { fg = c.gr[3] } },
  { 'NeutralFloat', { fg = c.gr[3] } },

  -- search
  { 'Search', { fg = c.bg[6], bg = c.pastel.blu } },
  { 'IncSearch', { fg = c.bg[6], bg = c.pastel.yel } },
  { 'CurSearch', { fg = c.bg[6], bg = c.pastel.pur } },
  { 'Substitute', { link = 'Search' } },
  { 'Visual', { fg = c.bg[6], bg = c.pastel.yel } },

  -- misc
  { 'CursorLine', { bg = c.bg[2] } },
  { 'CursorLineNr', { fg = c.pastel.gre } },
  { 'SpellBad', { sp = c.vivid.blu, underline = true } },
  { 'QuickFixLine', { fg = c.bg[6], bg = c.pastel.gre } },
  { 'Pmenu', { fg = c.fg[4], bg = c.bg[2] } },
  { 'PmenuSel', { fg = c.fg[2], bg = c.bg[1] } },
  { 'PmenuSbar', { bg = c.bg[1] } },
  { 'PmenuThumb', { bg = c.gr[1] } },

  ---- custom ----
  -- statusline
  { 'Statusline', { fg = c.fg[4], bg = c._ } },
  { 'StatuslineReadonly', { fg = c.pastel.red, bold = true } },
  { 'StatuslineLspinfo', { fg = c.gr[2] } },
  { 'StatuslineSearch', { fg = c.pastel.blu } },
  { 'StatuslineLocation', { fg = c.pastel.aqu } },

  { 'modeC', { fg = c.pastel.pur } },
  { 'modeI', { fg = c.pastel.blu } },
  { 'modeN', { fg = c.pastel.gre } },
  { 'modeR', { fg = c.pastel.yel } },
  { 'modeT', { fg = c.fg[2] } },
  { 'modeV', { fg = c.pastel.red } },

  { 'Git', { fg = c.misc.git } },
  { 'GitZero', { link = 'Grey' } },
  { 'GitAdd', { link = 'GreenSign' } },
  { 'GitCha', { link = 'BlueSign' } },
  { 'GitDel', { link = 'RedSign' } },

  -- tabline
  { 'TabActive', { fg = c.fg[2], bg = c.bg[2], bold = true } },
  { 'TabInactive', { fg = c.fg[3], bg = c.bg[3] } },

  ---- plugins ----
  -- gitsigns
  { 'GitSignsStagedAdd', { fg = c.darkened.gre } },
  { 'GitSignsStagedChange', { fg = c.darkened.blu } },
  { 'GitSignsStagedDelete', { fg = c.darkened.red } },
  { 'GitSignsStagedTopdelete', { fg = c.darkened.red } },
  { 'GitSignsStagedChangeDelete', { fg = c.darkened.blu } },

  -- telescope
  { 'TelescopeBorder', { fg = c.bg[1] } },
  { 'TelescopeMatching', { fg = c.pastel.red } },
  { 'TelescopeSelection', { fg = c.fg[1], bg = c.bg[2] } },
  { 'TelescopeSelectionCaret', { fg = c.fg[3], bg = c.bg[2] } },
  { 'TelescopeTitle', { link = 'Fg' } },
  { 'TelescopeNormal', { fg = c.fg[1] } },
  { 'TelescopePreviewTitle', { link = 'Fg' } },
  { 'TelescopePreviewNormal', { fg = c.fg[1] } },
  { 'TelescopePromptBorder', { link = 'TelescopeBorder' } },
  { 'TelescopePromptCounter', { link = 'Fg' } },
  { 'TelescopePromptNormal', { fg = c.fg[1] } },
  { 'TelescopePromptPrefix', { link = 'Fg' } },
  { 'TelescopePromptTitle', { link = 'Fg' } },

  -- treesitter
  { 'TreesitterContext', { bg = c.bg[2] } },
}

for i = 1, #highlights do
  vim.api.nvim_set_hl(0, highlights[i][1], highlights[i][2])
end

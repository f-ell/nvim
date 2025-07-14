-- scaffolding via MariaSolOs/dotfiles

vim.cmd.highlight('clear')
if vim.fn.exists('syntax_on') then
  vim.cmd.syntax('reset')
end
vim.g.colors_name = 'leafless'

LEAFLESS = {
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

  normal = {
    aqu = '#83c092',
    blu = '#7fbbb3',
    gre = '#a7c080',
    pur = '#d699b6',
    red = '#e67e80',
    yel = '#dbbc7f',
    ora = '#e69875',
  },
  bright = {
    cya = '#35a77c',
    blu = '#3a94c5',
    gre = '#8da101',
    pur = '#df69ba',
    red = '#f85552',
    yel = '#dfa000',
    ora = '#f57d26',
  },
  dim = {
    aqu = '#4f7459',
    blu = '#4d716d',
    gre = '#65744e',
    pur = '#825d6e',
    red = '#8b4c4e',
    yel = '#85724d',
  },
}

---@type table<string, vim.api.keyset.highlight>
local groups = {
  ---- generic ----
  Fg = { fg = LEAFLESS.fg[3] },
  Normal = { fg = LEAFLESS.fg[3] },
  NormalNC = { link = 'Normal' },
  NonText = { fg = LEAFLESS.gr[4] },
  Directory = { fg = LEAFLESS.bright.gre },
  Comment = { fg = LEAFLESS.gr[4], bold = true },
  Conceal = { link = 'Comment' },

  MatchParen = { fg = LEAFLESS.bright.gre, underline = true },
  SpecialKey = { link = 'NonText' },
  Underlined = { fg = LEAFLESS.bright.blu, underline = true },

  -- search
  Search = { fg = LEAFLESS.bg[6], bg = LEAFLESS.bright.blu },
  IncSearch = { fg = LEAFLESS.bg[6], bg = LEAFLESS.bright.yel },
  CurSearch = { fg = LEAFLESS.bg[6], bg = LEAFLESS.bright.pur },
  Substitute = { link = 'Search' },
  Visual = { fg = LEAFLESS.bg[6], bg = LEAFLESS.bright.yel },

  -- diff
  DiffAdd = { fg = LEAFLESS.bg[6], bg = LEAFLESS.bright.gre },
  DiffChange = { fg = LEAFLESS.bg[6], bg = LEAFLESS.bright.blu },
  DiffText = { fg = LEAFLESS.fg[1], bg = LEAFLESS.bright.blu },
  DiffDelete = { fg = LEAFLESS.bg[6], bg = LEAFLESS.bright.red },

  -- ui
  NormalFloat = { link = 'Fg' },
  NeutralFloat = { fg = LEAFLESS.gr[3] },
  FloatTitle = { link = 'Fg' },
  FloatBorder = { fg = LEAFLESS.gr[3] },
  WinSeparator = { fg = LEAFLESS.bg[1] },

  StatusLine = { link = 'Fg' },

  Pmenu = { fg = LEAFLESS.fg[3], bg = LEAFLESS.bg[2] },
  PmenuSel = { fg = LEAFLESS.fg[2], bg = LEAFLESS.bg[1] },
  PmenuSbar = { bg = LEAFLESS.bg[1] },
  PmenuThumb = { bg = LEAFLESS.gr[2] },

  CursorLine = { bg = LEAFLESS.bg[2] },
  CursorLineNr = { fg = LEAFLESS.bright.gre },
  Folded = { link = 'CursorLine' },
  QuickFixLine = { fg = LEAFLESS.bg[6], bg = LEAFLESS.bright.gre },

  MsgArea = { link = 'Fg' },
  MoreMsg = { link = 'NonText' },
  MsgSeparator = { fg = LEAFLESS.gr[3] },
  ModeMsg = { fg = LEAFLESS.bright.cya },
  WarningMsg = { fg = LEAFLESS.bright.yel },
  ErrorMsg = { fg = LEAFLESS.bright.red },
  Question = { link = 'NonText' },

  -- spell
  SpellBad = { sp = LEAFLESS.bright.blu, underline = true },
  SpellCap = { sp = LEAFLESS.bright.gre, underline = true },
  SpellRare = { sp = LEAFLESS.bright.pur, underline = true },
  SpellLocal = { sp = LEAFLESS.bright.cya, underline = true },

  ---- syntax ----
  Constant = { fg = LEAFLESS.fg[2] },
  String = { link = 'Constant' },
  Character = { link = 'Constant' },
  Number = { link = 'Constant' },
  Boolean = { link = 'Constant' },
  Float = { link = 'Constant' },

  Identifier = { fg = LEAFLESS.fg[2] },
  Function = { link = 'Identifier' },

  Statement = { link = 'Fg' },
  Conditional = { link = 'Statement' },
  Repeat = { link = 'Statement' },
  Label = { link = 'Statement' },
  Operator = { link = 'Statement' },
  Keyword = { link = 'Statement' },
  Exception = { link = 'Statement' },

  PreProc = { fg = LEAFLESS.gr[3] },
  Include = { link = 'PreProc' },
  Define = { link = 'PreProc' },
  Macro = { link = 'PreProc' },
  PreCondit = { link = 'PreProc' },

  Type = { link = 'Fg' },
  StorageClass = { link = 'Type' },
  Structure = { link = 'Type' },
  TypeDef = { link = 'Type' },

  Special = { link = 'Fg' },
  SpecialChar = { link = 'Special' },
  Tag = { link = 'Special' },
  Delimiter = { link = 'Special' },
  SpecialComment = { link = 'Special' },
  Debug = { link = 'Special' },

  Error = {
    fg = LEAFLESS.bright.red,
    sp = LEAFLESS.bright.red,
    underline = true,
  },

  ---- treesitter ----
  ['@annotation'] = { link = 'PreProc' },
  ['@attribute'] = { link = 'NonText' },
  ['@boolean'] = { link = 'Boolean' },
  ['@character'] = { link = 'Character' },
  ['@constant'] = { link = 'Constant' },
  ['@constant.builtin'] = { link = 'Constant' },
  ['@constant.macro'] = { link = 'Macro' },
  ['@constructor'] = { link = 'Type' },
  ['@error'] = { link = 'Error' },
  ['@function'] = { link = 'Function' },
  ['@function.builtin'] = { link = 'Constant' },
  ['@function.macro'] = { link = 'Macro' },
  ['@function.method'] = { link = 'Function' },
  ['@keyword'] = { link = 'Keyword' },
  ['@keyword.conditional'] = { link = 'Conditional' },
  ['@keyword.exception'] = { link = 'Error' },
  ['@keyword.function'] = { link = 'Function' },
  ['@keyword.function.ruby'] = { link = 'Function' },
  ['@keyword.include'] = { link = 'Include' },
  ['@keyword.operator'] = { link = 'Operator' },
  ['@keyword.repeat'] = { link = 'Repeat' },
  ['@label'] = { link = 'Label' },
  ['@markup'] = { link = 'NonText' },
  ['@markup.emphasis'] = { link = 'Comment' },
  ['@markup.heading'] = { bold = true },
  ['@markup.link'] = { underline = true },
  ['@markup.link.uri'] = { link = 'Underlined' },
  ['@markup.list'] = { link = 'NonText' },
  ['@markup.raw'] = { link = 'NonText' },
  ['@markup.strong'] = { bold = true },
  ['@markup.underline'] = { underline = true },
  ['@module'] = { link = 'Identifier' },
  ['@number'] = { link = 'Number' },
  ['@number.float'] = { link = 'Number' },
  ['@operator'] = { link = 'Operator' },
  ['@parameter.reference'] = { link = 'Special' },
  ['@property'] = { link = 'Constant' },
  ['@punctuation.bracket'] = { link = 'Delimiter' },
  ['@punctuation.delimiter'] = { link = 'Delimiter' },
  ['@string'] = { link = 'String' },
  ['@string.escape'] = { link = 'SpecialChar' },
  ['@string.regexp'] = { link = 'SpecialChar' },
  ['@string.special.symbol'] = { link = 'SpecialChar' },
  ['@structure'] = { link = 'Structure' },
  ['@tag'] = { link = 'Tag' },
  ['@tag.attribute'] = { link = '@attribute' },
  ['@tag.delimiter'] = { link = 'Delimiter' },
  ['@type'] = { link = 'Type' },
  ['@type.builtin'] = { link = 'Constant' },
  ['@type.qualifier'] = { link = 'Include' },
  ['@variable'] = { link = 'Identifier' },
  ['@variable.builtin'] = { link = '@variable' },
  ['@variable.member'] = { link = '@variable' },
  ['@variable.parameter'] = { link = '@variable' },

  ['@class'] = { link = 'TypeDef' },
  ['@decorator'] = { link = '@annotation' },
  ['@enum'] = { link = 'TypeDef' },
  ['@enumMember'] = { link = 'Constant' },
  ['@event'] = { link = '@annotation' },
  ['@interface'] = { link = 'TypeDef' },
  ['@lsp.type.class'] = { link = '@class' },
  ['@lsp.type.decorator'] = { link = '@decorator' },
  ['@lsp.type.enum'] = { link = '@enum' },
  ['@lsp.type.enumMember'] = { link = '@enumMember' },
  ['@lsp.type.function'] = { link = '@function' },
  ['@lsp.type.interface'] = { link = '@interface' },
  ['@lsp.type.macro'] = { link = '@constant.macro' },
  ['@lsp.type.method'] = { link = '@function.method' },
  ['@lsp.type.namespace'] = { link = 'PreProc' },
  ['@lsp.type.parameter'] = { link = '@variable.parameter' },
  ['@lsp.type.property'] = { link = '@property' },
  ['@lsp.type.struct'] = { link = '@structure' },
  ['@lsp.type.type'] = { link = '@type' },
  ['@lsp.type.variable'] = { link = '@variable' },
  ['@modifier'] = { link = '@decorator' },
  ['@regexp'] = { link = '@string.regexp' },
  ['@struct'] = { link = '@structure' },
  ['@typeParameter'] = { link = '@type' },

  ---- diagnostics ----
  ErrorText = { sp = LEAFLESS.bright.red, underline = true },
  WarningText = { sp = LEAFLESS.bright.yel, underline = true },
  InfoText = { sp = LEAFLESS.bright.gre, underline = true },
  HintText = { sp = LEAFLESS.bright.blu, underline = true },

  DiagnosticError = { fg = LEAFLESS.bright.red },
  DiagnosticWarn = { fg = LEAFLESS.bright.yel },
  DiagnosticInfo = { fg = LEAFLESS.bright.gre },
  DiagnosticHint = { fg = LEAFLESS.bright.blu },
  DiagnosticUnderlineError = { link = 'ErrorText' },
  DiagnosticUnderlineWarn = { link = 'WarningText' },
  DiagnosticUnderlineInfo = { link = 'InfoText' },
  DiagnosticUnderlineHint = { link = 'HintText' },
  DiagnosticSignError = { link = 'DiagnosticError' },
  DiagnosticSignWarn = { link = 'DiagnosticWarn' },
  DiagnosticSignInfo = { link = 'DiagnosticInfo' },
  DiagnosticSignHint = { link = 'DiagnosticHint' },

  DiagnosticOk = { fg = LEAFLESS.bright.pur },
  DiagnosticUnnecessary = { fg = LEAFLESS.gr[4] },
  DiagnosticDeprecated = { strikethrough = true },

  ---- plugins ----
  -- gitsigns
  GitSignsAdd = { fg = LEAFLESS.bright.gre },
  GitSignsChange = { fg = LEAFLESS.bright.blu },
  GitSignsDelete = { fg = LEAFLESS.bright.red },
  GitSignsStagedAdd = { fg = LEAFLESS.dim.gre },
  GitSignsStagedChange = { fg = LEAFLESS.dim.blu },
  GitSignsStagedDelete = { fg = LEAFLESS.dim.red },
  GitSignsStagedTopdelete = { fg = LEAFLESS.dim.red },
  GitSignsStagedChangeDelete = { fg = LEAFLESS.dim.blu },

  -- telescope
  TelescopeBorder = { link = 'WinSeparator' },
  TelescopeMatching = { fg = LEAFLESS.bright.red },
  TelescopeSelection = { link = 'CursorLine' },
  TelescopeSelectionCaret = { fg = LEAFLESS.bright.gre, bg = LEAFLESS.bg[2] },
  TelescopeTitle = { link = 'Fg' },
  TelescopePreviewTitle = { link = 'Fg' },
  TelescopePromptBorder = { link = 'TelescopeBorder' },
  TelescopePromptCounter = { link = 'NonText' },
  TelescopePromptPrefix = { fg = LEAFLESS.bright.gre },
  TelescopePromptTitle = { link = 'Fg' },

  -- treesitter
  TreesitterContext = { link = 'CursorLine' },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end

-- scaffolding via MariaSolOs/dotfiles

if vim.g.colors_name then
  vim.cmd.hi('clear')
end
if vim.fn.exists('syntax_on') then
  vim.cmd.syntax('reset')
end

vim.g.colors_name = 'leafless'

if vim.o.background == 'dark' then
  LEAFLESS = {
    fg = {
      '#e0dbd0',
      '#d5cfc1',
      '#cac3b3',
      '#bfb7a5',
    },
    gr = {
      '#94949c',
      '#80838b',
      '#6c727a',
      '#596269',
    },
    bg = {
      '#465258',
      '#3c464b',
      '#323c41',
      '#191b1d',
    },

    normal = {
      cya = '#83c092',
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
      cya = '#4f7459',
      blu = '#4d716d',
      gre = '#65744e',
      pur = '#825d6e',
      red = '#8b4c4e',
      yel = '#85724d',
    },
  }
else
  LEAFLESS = {
    fg = {
      '#465258',
      '#3c464b',
      '#323c41',
      '#191b1d',
    },
    gr = {
      '#c4beb2',
      '#aea79d',
      '#989088',
      '#827a74',
    },
    bg = {
      '#dbd6c8',
      '#e3ded0',
      '#eae7d7',
      '#f2efdf',
    },

    normal = {
      cya = '#35a77c',
      blu = '#3a94c5',
      gre = '#8da101',
      pur = '#df69ba',
      red = '#f85552',
      yel = '#dfa000',
      ora = '#f57d26',
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
      cya = '#83c092',
      blu = '#7fbbb3',
      gre = '#a7c080',
      pur = '#d699b6',
      red = '#e67e80',
      yel = '#dbbc7f',
      ora = '#e69875',
    },
  }
end

---@type table<string, vim.api.keyset.highlight>
local groups = {
  ---- builtin ----
  ColorColumn = { bg = LEAFLESS.bg[2] },
  Conceal = { fg = LEAFLESS.gr[4] },
  CurSearch = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.pur },
  Cursor = { fg = LEAFLESS.bg[4], bg = LEAFLESS.fg[1] },
  lCursor = { link = 'Cursor' },
  CursorIM = { link = 'Cursor' },
  CursorColumn = { bg = LEAFLESS.bg[1] },
  CursorLine = { bg = LEAFLESS.bg[2] },
  Directory = { fg = LEAFLESS.bright.yel },

  DiffAdd = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.gre },
  DiffChange = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.blu },
  DiffDelete = { fg = LEAFLESS.gr[4], bg = nil },
  DiffText = { fg = LEAFLESS.fg[1], bg = LEAFLESS.bright.blu, underline = true },

  EndOfBuffer = { link = 'NonText' },
  TermCursor = { link = 'Cursor' },
  ErrorMsg = { fg = LEAFLESS.bright.red },
  WinSeparator = { fg = LEAFLESS.gr[4] },
  Folded = { link = 'CursorLine' },
  FoldColumn = { link = 'NonText' },
  SignColumn = { link = 'NonText' },
  IncSearch = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.yel },
  Substitute = { link = 'Search' },

  LineNr = { fg = LEAFLESS.gr[3] },
  LineNrAbove = { link = 'LineNr' },
  LineNrBelow = { link = 'LineNr' },
  CursorLineNr = { fg = LEAFLESS.bright.gre },
  CursorLineFold = { link = 'FoldColumn' },
  CursorLineSign = { link = 'SignColumn' },

  MatchParen = { fg = LEAFLESS.bright.gre, underline = true },
  ModeMsg = { fg = LEAFLESS.bright.cya },
  MsgArea = { link = 'Normal' },
  MsgSeparator = { link = 'WinSeparator' },
  MoreMsg = { link = 'NonText' },
  NonText = { fg = LEAFLESS.gr[3] },
  Normal = { fg = LEAFLESS.fg[2], bg = LEAFLESS.bg[3] },
  NormalFloat = { link = 'Normal' },
  FloatBorder = { fg = LEAFLESS.gr[4] },
  FloatTitle = { link = 'Normal' },
  FloatFooter = { link = 'FloatTitle' },
  NormalNC = { link = 'Normal' },

  Pmenu = { bg = LEAFLESS.bg[2] },
  PmenuSel = { bg = LEAFLESS.bg[1] },
  PmenuKind = { link = 'Pmenu' },
  PmenuKindSel = { link = 'PmenuSel' },
  PmenuExtra = { link = 'Pmenu' },
  PmenuExtraSel = { link = 'PmenuExtra' },
  PmenuSbar = { bg = LEAFLESS.bg[1] },
  PmenuThumb = { bg = LEAFLESS.gr[1] },
  PmenuMatch = { underline = true },
  PmenuMatchSel = { link = 'PmenuMatch' },

  ComplMatchIns = { fg = LEAFLESS.bright.gre },
  Question = { link = 'NonText' },
  QuickFixLine = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.gre },
  Search = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.blu },
  SnippetTabstop = { link = 'Visual' },
  SpecialKey = { link = 'NonText' },

  SpellBad = { sp = LEAFLESS.bright.blu, underline = true },
  SpellCap = { sp = LEAFLESS.bright.gre, underline = true },
  SpellLocal = { sp = LEAFLESS.bright.cya, underline = true },
  SpellRare = { sp = LEAFLESS.bright.pur, underline = true },

  StatusLine = { bg = LEAFLESS.bg[2] },
  StatusLineNC = { link = 'StatusLine' },
  StatusLineTerm = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.gre },
  StatusLineTermNC = { link = 'StatusLineTerm' },
  TabLine = { link = 'Normal' },
  TabLineFill = { bg = LEAFLESS.bg[2] },
  TabLineSel = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.gre },
  Title = { fg = LEAFLESS.bright.pur },

  Visual = { fg = LEAFLESS.bg[4], bg = LEAFLESS.bright.yel },
  VisualNOS = { link = 'Visual' },
  WarningMsg = { fg = LEAFLESS.bright.yel },
  Whitespace = { link = 'NonText' },
  WildMenu = { link = 'ComplMatchIns' },
  WinBar = { link = 'NormalFloat' },
  WinBarNC = { link = 'WinBar' },

  Added = { fg = LEAFLESS.bright.gre },
  Changed = { fg = LEAFLESS.bright.blu },
  Removed = { fg = LEAFLESS.bright.red },

  ---- syntax ----
  Comment = { fg = LEAFLESS.gr[3], bold = true },

  Constant = { fg = LEAFLESS.fg[1] },
  String = { link = 'Constant' },
  Character = { link = 'Constant' },
  Number = { link = 'Constant' },
  Boolean = { link = 'Constant' },
  Float = { link = 'Constant' },

  Identifier = { fg = LEAFLESS.fg[1] },
  Function = { link = 'Identifier' },

  Statement = { fg = LEAFLESS.fg[2] },
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

  Type = { fg = LEAFLESS.fg[2] },
  StorageClass = { link = 'Type' },
  Structure = { link = 'Type' },
  TypeDef = { link = 'Type' },

  -- FWIW: this makes it really hard to see fields in Zig struct initialization:
  -- whitespace, i.e. `.`, before a field, e.g. `.data`, has the same colour.
  Special = { fg = LEAFLESS.gr[3] },
  SpecialChar = { link = 'Special' },
  Tag = { link = 'Special' },
  Delimiter = { link = 'Special' },
  SpecialComment = { link = 'Special' },
  Debug = { link = 'Special' },

  Underlined = { fg = LEAFLESS.bright.blu, underline = true },
  Error = {
    fg = LEAFLESS.bright.red,
    sp = LEAFLESS.bright.red,
    underline = true,
  },
  Todo = { bg = nil },

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

  DiagnosticOk = { sp = LEAFLESS.bright.cya, underline = true },
  DiagnosticUnnecessary = { sp = LEAFLESS.bright.pur, underline = true },
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
  TelescopeTitle = { link = 'Normal' },
  TelescopePreviewTitle = { link = 'Normal' },
  TelescopePromptBorder = { link = 'TelescopeBorder' },
  TelescopePromptCounter = { link = 'NonText' },
  TelescopePromptPrefix = { fg = LEAFLESS.bright.gre },
  TelescopePromptTitle = { link = 'Normal' },

  -- treesitter
  TreesitterContext = { link = 'CursorLine' },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end

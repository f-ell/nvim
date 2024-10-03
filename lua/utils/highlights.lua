local c = {
  _ = '',

  fg = {
    '#fdf6e3',
    '#d3c6aa',
    '#859289',
  },
  bg = {
    '#434f55',
    '#374247',
    '#2a3439',
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
  misc = {
    git = '#fca326',
    yel = '#65645a',
  },
}

local highlights = {
  ---- builtin ----
  -- diagnostics
  { 'ErrorText', { sp = c.pastel.red, underline = true } },
  { 'WarningText', { sp = c.pastel.yel, underline = true } },
  { 'InfoText', { sp = c.pastel.gre, underline = true } },
  { 'HintText', { sp = c.pastel.blu, underline = true } },
  { 'DiagnosticOk', { fg = c.pastel.pur } },
  { 'DiagnosticSignError', { fg = c.pastel.red } },
  { 'DiagnosticSignWarn', { fg = c.pastel.yel } },
  { 'DiagnosticSignInfo', { fg = c.pastel.gre } },
  { 'DiagnosticSignHint', { fg = c.pastel.blu } },
  { 'DiagnosticUnderlineError', { sp = c.pastel.red, underline = true } },
  { 'DiagnosticUnderlineWarn', { sp = c.pastel.yel, underline = true } },
  { 'DiagnosticUnderlineInfo', { sp = c.pastel.gre, underline = true } },
  { 'DiagnosticUnderlineHint', { sp = c.pastel.blu, underline = true } },

  -- diff
  { 'DiffText', { bg = '#3d5665', sp = c.pastel.blu, underline = true } },
  { 'DiffDelete', { fg = c.fg[3], bg = c._ } },

  -- float
  { 'NormalFloat', { fg = c._, bg = c._ } },
  { 'FloatTitle', { fg = c.fg[2], bg = c._ } },
  { 'FloatBorder', { fg = c.fg[3], bg = c._ } },
  { 'NeutralFloat', { fg = c.fg[3], bg = c._ } },

  -- search
  { 'Search', { fg = c.fg[2], bg = c.misc.yel } },
  { 'IncSearch', { fg = c.bg[3], bg = c.pastel.yel } },
  { 'CurSearch', { link = 'IncSearch' } },
  { 'Substitute', { link = 'IncSearch' } },
  { 'Visual', { fg = c._, bg = '#3d5665' } },

  -- misc
  { 'CursorLineNr', { fg = c.pastel.gre } },
  { 'SpellBad', { sp = c.pastel.red, undercurl = true } },
  { 'QuickFixLine', { fg = c.bg[3], bg = c.pastel.gre } },

  ---- custom ----
  -- statusline
  { 'Statusline', { fg = c.fg[2], bg = c._ } },
  { 'FoldColumn', { fg = c.fg[3], bg = c._ } },
  { 'StatuslineReadonly', { fg = c.pastel.red, bg = c._, bold = true } },
  { 'StatuslineLspinfo', { fg = c.fg[3], bg = c._ } },
  { 'StatuslineSearch', { fg = c.pastel.blu, bg = c._ } },
  { 'StatuslineLocation', { fg = c.pastel.aqu, bg = c._ } },

  { 'modeC', { fg = c.pastel.pur, bg = c._ } },
  { 'modeI', { fg = c.pastel.blu, bg = c._ } },
  { 'modeN', { fg = c.pastel.gre, bg = c._ } },
  { 'modeR', { fg = c.pastel.yel, bg = c._ } },
  { 'modeT', { fg = c.fg[3], bg = c._ } },
  { 'modeV', { fg = c.pastel.red, bg = c._ } },

  { 'Git', { fg = c.misc.git, bg = c._ } },
  { 'GitZero', { link = 'Grey' } },
  { 'GitAdd', { link = 'GreenSign' } },
  { 'GitCha', { link = 'BlueSign' } },
  { 'GitDel', { link = 'RedSign' } },

  -- tabline
  { 'TabActive', { fg = c.fg[2], bg = c.bg[2], bold = true } },
  { 'TabInactive', { fg = c.fg[3], bg = c.bg[3] } },

  ---- plugins ----
  -- cmp
  { 'CmpFloat', { fg = c.fg[3], bg = c.bg[2] } },
  { 'CmpSel', { fg = c.bg[3], bg = c.pastel.red } },
  { 'CmpItemMenu', { fg = c.fg[3], bg = c._ } },
  { 'CmpItemAbbrMatch', { fg = c.pastel.red, bg = c._ } },
  { 'CmpItemAbbrMatchFuzzy', { fg = c.pastel.red, bg = c._ } },
  { 'CmpItemKindText', { fg = c.pastel.blu } },

  -- dap
  { 'DapStopped', { fg = c.pastel.gre } },
  { 'DapLogPoint', { fg = c.pastel.yel } },
  { 'DapBreakpoint', { fg = c.pastel.red } },
  { 'DapBreakpointCondition', { fg = c.pastel.pur } },
  { 'DapBreakpointRejected', { fg = c.pastel.red } },

  -- gitsigns
  { 'GitSignsStagedAdd', { fg = c.darkened.gre } },
  { 'GitSignsStagedChange', { fg = c.darkened.blu } },
  { 'GitSignsStagedDelete', { fg = c.darkened.red } },
  { 'GitSignsStagedTopdelete', { fg = c.darkened.red } },
  { 'GitSignsStagedChangeDelete', { fg = c.darkened.blu } },

  -- telescope
  { 'TelescopeBorder', { fg = c.fg[3], bg = c._ } },
  { 'TelescopeMatching', { fg = c.pastel.red, bg = c._ } },
  { 'TelescopeSelection', { fg = c.fg[1], bg = c.bg[2] } },
  { 'TelescopeTitle', { fg = c.pastel.red, bg = c._ } },
  { 'TelescopeNormal', { fg = c.fg[1], bg = c._ } },
  { 'TelescopePreviewTitle', { fg = c.pastel.blu, bg = c._ } },
  { 'TelescopePreviewNormal', { fg = c.fg[1], bg = c._ } },
  { 'TelescopePromptBorder', { fg = c.fg[3], bg = c._ } },
  { 'TelescopePromptCounter', { fg = c.pastel.gre, bg = c._ } },
  { 'TelescopePromptNormal', { fg = c.fg[1], bg = c._ } },
  { 'TelescopePromptPrefix', { fg = c.pastel.gre, bg = c._ } },
  { 'TelescopePromptTitle', { fg = c.pastel.gre, bg = c._ } },

  -- treesitter
  { 'TreesitterContext', { fg = c._, bg = c.bg[2] } },
  { 'TreesitterContextLineNumber', { fg = c.fg[3], bg = c._ } },
}

for i = 1, #highlights do
  vim.api.nvim_set_hl(0, highlights[i][1], highlights[i][2])
end

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
  -- search
  { 0, 'Search', { fg = c.fg[2], bg = c.misc.yel } },
  { 0, 'IncSearch', { fg = c.bg[3], bg = c.pastel.yel } },
  { 0, 'CurSearch', { link = 'IncSearch' } },
  { 0, 'Substitute', { link = 'IncSearch' } },
  { 0, 'Visual', { fg = c._, bg = '#3d5665' } },

  -- diagnostics
  { 0, 'ErrorText', { sp = c.pastel.red, underline = true } },
  { 0, 'WarningText', { sp = c.pastel.yel, underline = true } },
  { 0, 'InfoText', { sp = c.pastel.gre, underline = true } },
  { 0, 'HintText', { sp = c.pastel.blu, underline = true } },
  { 0, 'DiagnosticOk', { fg = c.pastel.pur } },
  { 0, 'DiagnosticSignError', { fg = c.pastel.red } },
  { 0, 'DiagnosticSignWarn', { fg = c.pastel.yel } },
  { 0, 'DiagnosticSignInfo', { fg = c.pastel.gre } },
  { 0, 'DiagnosticSignHint', { fg = c.pastel.blu } },
  { 0, 'DiagnosticUnderlineError', { sp = c.pastel.red, underline = true } },
  { 0, 'DiagnosticUnderlineWarn', { sp = c.pastel.yel, underline = true } },
  { 0, 'DiagnosticUnderlineInfo', { sp = c.pastel.gre, underline = true } },
  { 0, 'DiagnosticUnderlineHint', { sp = c.pastel.blu, underline = true } },

  -- float
  { 0, 'NormalFloat', { fg = c._, bg = c._ } },
  { 0, 'FloatTitle', { fg = c.fg[2], bg = c._ } },
  { 0, 'FloatBorder', { fg = c.fg[3], bg = c._ } },

  { 0, 'NeutralFloat', { fg = c.fg[3], bg = c._ } },

  -- statusline
  { 0, 'Statusline', { fg = c.fg[2], bg = c._ } },
  {
    0,
    'StatuslineReadonly',
    { fg = c.pastel.red, bg = c._, bold = true },
  },
  { 0, 'StatuslineLspinfo', { fg = c.fg[3], bg = c._ } },
  { 0, 'StatuslineBytecount', { fg = c.pastel.yel, bg = c._ } },
  { 0, 'StatuslineSearch', { fg = c.pastel.blu, bg = c._ } },
  { 0, 'StatuslineLocation', { fg = c.pastel.aqu, bg = c._ } },

  { 0, 'modeC', { fg = c.pastel.pur, bg = c._ } },
  { 0, 'modeI', { fg = c.pastel.blu, bg = c._ } },
  { 0, 'modeN', { fg = c.pastel.gre, bg = c._ } },
  { 0, 'modeR', { fg = c.pastel.yel, bg = c._ } },
  { 0, 'modeT', { fg = c.fg[3], bg = c._ } },
  { 0, 'modeV', { fg = c.pastel.red, bg = c._ } },

  -- tabline
  { 0, 'TabActive', { fg = c.fg[2], bg = c.bg[2], bold = true } },
  { 0, 'TabInactive', { fg = c.fg[3], bg = c.bg[3] } },

  -- misc
  {
    0,
    'DiffText',
    { bg = '#3d5665', sp = c.pastel.blu, underline = true },
  },
  { 0, 'DiffDelete', { fg = c.fg[3], bg = c._ } },

  { 0, 'Git', { fg = c.misc.git, bg = c._ } },
  { 0, 'GitZero', { link = 'Grey' } },
  { 0, 'GitAdd', { link = 'GreenSign' } },
  { 0, 'GitCha', { link = 'BlueSign' } },
  { 0, 'GitDel', { link = 'RedSign' } },
  { 0, 'GitSignsStagedAdd', { fg = c.darkened.gre } },
  { 0, 'GitSignsStagedChange', { fg = c.darkened.blu } },
  { 0, 'GitSignsStagedDelete', { fg = c.darkened.red } },
  { 0, 'GitSignsStagedTopdelete', { fg = c.darkened.red } },
  { 0, 'GitSignsStagedChangeDelete', { fg = c.darkened.blu } },

  { 0, 'SpellBad', { sp = c.pastel.red, undercurl = true } },
  { 0, 'QuickFixLine', { fg = c.bg[3], bg = c.pastel.gre } },

  ---- plugins ----
  -- cmp
  { 0, 'CmpFloat', { fg = c.fg[3], bg = c.bg[2] } },
  { 0, 'CmpSel', { fg = c.bg[3], bg = c.pastel.red } },
  { 0, 'CmpItemMenu', { fg = c.fg[3], bg = c._ } },
  { 0, 'CmpItemAbbrMatch', { fg = c.pastel.red, bg = c._ } },
  { 0, 'CmpItemAbbrMatchFuzzy', { fg = c.pastel.red, bg = c._ } },
  { 0, 'CmpItemKindText', { fg = c.pastel.blu } },

  -- dap
  { 0, 'DapStopped', { fg = c.pastel.gre } },
  { 0, 'DapLogPoint', { fg = c.pastel.yel } },
  { 0, 'DapBreakpoint', { fg = c.pastel.red } },
  { 0, 'DapBreakpointCondition', { fg = c.pastel.pur } },
  { 0, 'DapBreakpointRejected', { fg = c.pastel.red } },

  -- telescope
  { 0, 'TelescopeBorder', { fg = c.fg[3], bg = c._ } },
  { 0, 'TelescopeMatching', { fg = c.pastel.red, bg = c._ } },
  { 0, 'TelescopeSelection', { fg = c.fg[1], bg = c.bg[2] } },
  { 0, 'TelescopeTitle', { fg = c.pastel.red, bg = c._ } },
  { 0, 'TelescopeNormal', { fg = c.fg[1], bg = c._ } },
  { 0, 'TelescopePreviewTitle', { fg = c.pastel.blu, bg = c._ } },
  { 0, 'TelescopePreviewNormal', { fg = c.fg[1], bg = c._ } },
  { 0, 'TelescopePromptBorder', { fg = c.fg[3], bg = c._ } },
  { 0, 'TelescopePromptCounter', { fg = c.pastel.gre, bg = c._ } },
  { 0, 'TelescopePromptNormal', { fg = c.fg[1], bg = c._ } },
  { 0, 'TelescopePromptPrefix', { fg = c.pastel.gre, bg = c._ } },
  { 0, 'TelescopePromptTitle', { fg = c.pastel.gre, bg = c._ } },

  -- treesitter
  { 0, 'TreesitterContext', { fg = c._, bg = c.bg[2] } },
  { 0, 'TreesitterContextLineNumber', { fg = c.fg[3], bg = c._ } },
}

for i = 1, #highlights do
  vim.api.nvim_set_hl(highlights[i][1], highlights[i][2], highlights[i][3])
end

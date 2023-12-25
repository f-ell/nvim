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
  },
}

local highlights = {
  -- search
  { 0, 'Search', { fg = c.bg[3], bg = c.pastel.gre } },
  { 0, 'IncSearch', { fg = c.bg[3], bg = c.pastel.red } },
  { 0, 'CurSearch', { link = 'IncSearch' } },
  { 0, 'Substitute', { link = 'IncSearch' } },
  { 0, 'Visual', { fg = c._, bg = '#3d5665' } },

  -- diagnostics
  { 0, 'ErrorText', { sp = c.pastel.red, underline = true } },
  { 0, 'WarningText', { sp = c.pastel.yel, underline = true } },
  { 0, 'InfoText', { sp = c.pastel.gre, underline = true } },
  { 0, 'HintText', { sp = c.pastel.blu, underline = true } },
  { 0, 'DiagnosticSignError', { fg = c.pastel.red } },
  { 0, 'DiagnosticSignWarn', { fg = c.pastel.yel } },
  { 0, 'DiagnosticSignInfo', { fg = c.pastel.gre } },
  { 0, 'DiagnosticSignHint', { fg = c.pastel.blu } },

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
  { 0, 'TlActive', { fg = c.fg[2], bg = c.bg[2], bold = true } },
  { 0, 'TlInactive', { fg = c.fg[3], bg = c.bg[3] } },

  -- misc
  { 0, 'SpellBad', { sp = c.pastel.red, undercurl = true } },
  { 0, 'Git', { fg = c.misc.git, bg = c._ } },
  { 0, 'GitZero', { fg = c.fg[3], bg = c._ } },
  { 0, 'GitAdd', { fg = c.pastel.gre, bg = c._ } },
  { 0, 'GitCha', { fg = c.pastel.blu, bg = c._ } },
  { 0, 'GitDel', { fg = c.pastel.red, bg = c._ } },

  ---- plugins ----
  -- cmp
  { 0, 'CmpItemMenu', { fg = c.fg[3], bg = c._ } },
  { 0, 'CmpItemAbbrMatch', { fg = c.pastel.red, bg = c._ } },
  { 0, 'CmpItemAbbrMatchFuzzy', { fg = c.pastel.red, bg = c._ } },

  -- dap
  { 0, 'DapStopped', { fg = c.pastel.gre } },
  { 0, 'DapLogPoint', { fg = c.pastel.yel } },
  { 0, 'DapBreakpoint', { fg = c.pastel.red } },
  { 0, 'DapBreakpointCondition', { fg = c.pastel.pur } },
  { 0, 'DapBreakpointRejected', { fg = c.pastel.red } },

  -- gitsigns
  {
    0,
    'DiffText',
    { bg = '#3d5665', sp = c.pastel.blu, underline = true },
  },
  { 0, 'DiffDelete', { fg = c.fg[3], bg = c._ } },
  { 0, 'GSAdd', { fg = c.pastel.gre, bg = c._ } },
  { 0, 'GSCha', { fg = c.pastel.blu, bg = c._ } },
  { 0, 'GSDel', { fg = c.pastel.red, bg = c._ } },
  { 0, 'GSAddNr', { link = 'GitsignsAddNr' } },
  { 0, 'GSAddLn', { link = 'GitSignsAddLn' } },
  { 0, 'GSChaNr', { link = 'GitSignsChangeNr' } },
  { 0, 'GSChaLn', { link = 'GitSignsChangeLn' } },
  { 0, 'GSDelNr', { link = 'GitSignsDeleteNr' } },
  { 0, 'GSDelLn', { link = 'GitSignsDeleteLn' } },

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

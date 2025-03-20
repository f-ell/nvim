local M = {
  ---@type table<string, vim.api.keyset.highlight>
  groups = {
    -- statusline
    StatusLineReadonly = { fg = LEAFLESS.bright.red },
    StatusLineLspinfo = { link = 'NonText' },
    StatusLineSearch = { fg = LEAFLESS.bright.blu },
    StatusLineLocation = { fg = LEAFLESS.bright.cya },

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
  },
}

function M:set()
  for name, spec in pairs(self.groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

return M

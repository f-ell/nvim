return {
  'nvim-tree/nvim-web-devicons',
  lazy = true,
  config = function()
    -- inspired by projekt0n/circles.nvim
    local nwd = require('nvim-web-devicons')

    local override = {}
    for n, i in pairs(nwd.get_icons()) do
      -- This modifies the underlying data structure. This doesn't affect
      -- us, since we (i) provide overrides and (ii) the plugin resets icons
      -- on colorscheme changes.
      i.icon = '•'
      override[n] = i
    end

    nwd.setup({ default = true, override = override })
    nwd.set_default_icon('◦', '#859289')
  end,
}

return {
  'saghen/blink.cmp',
  lazy = true,
  event = { 'InsertEnter', 'CmdlineEnter' },
  version = 'v0.*', -- download release binary
  dependencies = 'folke/lazydev.nvim',
  opts = {
    keymap = {
      preset = 'none',

      ['<C-Space>'] = { 'show' },
      ['<C-e>'] = {
        'hide',
        'fallback' --[[prevent ins-completion shadowing]],
      },
      ['<C-l>'] = { 'accept' },
      ['<C-k>'] = { 'select_prev' },
      ['<C-j>'] = { 'select_next' },

      ['<C-d>'] = { 'show_documentation', 'hide_documentation' },
      ['<C-b>'] = { 'snippet_backward', 'scroll_documentation_up' },
      ['<C-f>'] = { 'snippet_forward', 'scroll_documentation_down' },
    },

    fuzzy = {
      use_frecency = false,
      max_typos = function()
        return 0
      end,
    },

    completion = {
      keyword = { range = 'full' },
      trigger = { show_on_insert_on_trigger_character = false },

      accept = {
        create_undo_point = true,
        auto_brackets = { enabled = false },
      },

      list = {
        selection = {
          auto_insert = function(ctx)
            return ctx.mode == 'cmdline'
          end,
        },
      },

      menu = {
        max_height = 12,
        border = 'none',
        winhighlight = 'Normal:BlinkCmpMenu,CursorLine:BlinkCmpMenuSelection,Search:None',
        scrolloff = 1,

        draw = {
          columns = { { 'kind_icon' }, { 'label', 'source_name', gap = 1 } },
          components = {
            label = {
              width = { fill = true, max = 64 },
              ellipsis = true,
              highlight = function(ctx)
                return 'BlinkCmpLabel'
                  .. (ctx.deprecated and 'Deprecated' or 'Detail')
              end,
            },
          },
        },
      },

      documentation = {
        auto_show = true,
        window = {
          min_width = 32,
          max_width = 128,
          border = 'single',
          winhighlight = 'FloatBorder:FloatBorder,Search:None',
        },
      },
    },

    cmdline = {
      keymap = { preset = 'inherit' },
    },

    sources = {
      default = { 'cmdline', 'lazydev', 'lsp', 'path' },
      providers = {
        cmdline = {
          name = 'cmdline',
          module = 'blink.cmp.sources.cmdline',
          transform_items = function(ctx, items)
            return ctx.mode == 'cmdline' and items or {}
          end,
        },
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100,
        },
        lsp = {
          name = 'lsp',
          module = 'blink.cmp.sources.lsp',
          transform_items = function(_, items)
            return vim
              .iter(items)
              :filter(function(i)
                return i.kind ~= 15
              end)
              :totable()
          end,
        },
        path = {
          name = 'path',
          module = 'blink.cmp.sources.path',
          score_offset = -100,
        },
      },
    },

    appearance = {
      -- stylua: ignore
      kind_icons = {
        Text     = '', Method = '󰡱', Function  = '󰊕', Constructor = '󰙴', Field         = '∊',
        Variable = '󰀫', Class  = '󰠲', Interface = '󱡠', Module      = '󰆧', Property      = '󰖷',
        Unit     = '󰿦', Value  = '󰎠', Enum      = '󱀍', Keyword     = '󰻾', Snippet       = '',
        Color    = '', File   = '󰦨', Reference = '', Folder      = '󰉋', EnumMember    = '󰀬',
        Constant = '', Struct = '󰅩', Event     = '', Operator    = '±', TypeParameter = '󰒓',
      },
    },
  },
}

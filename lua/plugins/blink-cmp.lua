return {
  'saghen/blink.cmp',
  lazy = true,
  event = { 'InsertEnter', 'CmdlineEnter' },
  version = 'v0.*', -- download release binary
  dependencies = 'folke/lazydev.nvim',
  opts = {
    keymap = {
      ['<C-Space>'] = { 'show' },
      ['<C-e>'] = { 'hide' },
      ['<C-l>'] = { 'accept' },
      ['<C-k>'] = { 'select_prev' },
      ['<C-j>'] = { 'select_next' },

      ['<C-d>'] = { 'show_documentation', 'hide_documentation' },
      ['<C-b>'] = { 'snippet_backward', 'scroll_documentation_up' },
      ['<C-f>'] = { 'snippet_forward', 'scroll_documentation_down' },
    },

    fuzzy = {
      use_frecency = false,
      use_typo_resistance = false,
    },

    completion = {
      keyword = { range = 'full' },
      trigger = { show_on_insert_on_trigger_character = false },

      accept = {
        create_undo_point = true,
        auto_brackets = {
          enabled = true,
          default_brackets = { '(', '' },
        },
      },

      menu = {
        max_height = 8,
        border = 'none',
        winhighlight = 'Normal:BlinkCmpMenu,CursorLine:BlinkCmpMenuSelection,Search:None',
        scrolloff = 1,

        draw = {
          columns = { { 'kind_icon' }, { 'label', 'source', gap = 1 } },
          components = {
            label = {
              width = { fill = true, max = 48 },
              ellipsis = true,
              text = function(ctx)
                return ctx.item.label
              end,
              highlight = function(ctx)
                return ctx.deprecated and 'BlinkCmpLabelDeprecated'
                  or 'BlinkCmpLabel'
              end,
            },

            source = {
              text = function(ctx)
                return ctx.item.source_name:sub(0, 1):upper()
              end,
              highlight = function()
                return 'NeutralFloat'
              end,
            },
          },
        },
      },

      documentation = {
        auto_show = true,
        window = {
          min_width = 32,
          max_width = 64,
          max_height = 24,
          border = 'single',
          winhighlight = 'FloatBorder:FloatBorder,Search:None',
        },
      },
    },

    sources = {
      default = { 'buffer', 'cmdline', 'lazydev', 'lsp', 'path' },
      providers = {
        buffer = {
          name = 'buffer',
          module = 'blink.cmp.sources.buffer',
          score_offset = -2,
        },
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
          fallbacks = { 'lsp' },
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
          fallbacks = { 'buffer' },
        },
        path = {
          name = 'path',
          module = 'blink.cmp.sources.path',
          score_offset = -1,
        },
      },
    },

    appearance = {
      use_nvim_cmp_as_default = true,
      -- stylua: ignore
      kind_icons = {
        Text     = '', Method = '󰡱', Function  = '', Constructor = '', Field         = '∊',
        Variable = '󰀫', Class  = '󰠲', Interface = '', Module      = '', Property      = '∊',
        Unit     = '󰔌', Value  = '', Enum      = '󱀍', Keyword     = '', Snippet       = '',
        Color    = '', File   = '󰦨', Reference = '', Folder      = '', EnumMember    = '',
        Constant = 'c', Struct = '', Event     = '󱐋', Operator    = '±', TypeParameter = 'T',
      }, -- 󰙅 |  |  | 󰻾
    },
  },
}

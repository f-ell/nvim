-- stylua: ignore
local icons = {
  Text     = '', Method = '󰡱', Function  = '', Constructor = '', Field         = '∊',
  Variable = '󰀫', Class  = '󰠲', Interface = '', Module      = '', Property      = '∊',
  Unit     = '󰔌', Value  = '', Enum      = '󱀍', Keyword     = '', Snippet       = '',
  Color    = '', File   = '󰦨', Reference = '', Folder      = '', EnumMember    = '',
  Constant = 'c', Struct = '', Event     = '󱐋', Operator    = '±', TypeParameter = 'T',
} -- 󰙅 |  | 

return {
  'hrsh7th/nvim-cmp',
  lazy = true,
  priority = 1000,
  event = 'InsertEnter',
  dependencies = {
    'dcampos/nvim-snippy',
    'hrsh7th/cmp-buffer',
    { 'hrsh7th/cmp-cmdline', event = 'CmdlineEnter' },
  },
  opts = {
    enabled = function()
      local context = require('cmp.config.context')
      return not context.in_treesitter_capture('comment')
        and not context.in_syntax_group('Comment')
    end,

    matching = {
      disallow_fuzzy_matching = true,
      disallow_fullfuzzy_matching = true,
      disallow_partial_fuzzy_matching = false,
      disallow_partial_matching = false,
      disallow_prefix_unmatching = false,
      disallow_symbol_nonprefix_matching = true,
    },

    snippet = {
      expand = function(arg)
        require('snippy').expand_snippet(arg.body)
      end,
    },

    sources = {
      {
        name = 'snippy',
        max_item_count = 4,
        keyword_length = 1,
      },
      { name = 'lazydev', group_index = 0 },
      {
        name = 'nvim_lsp',
        keyword_length = 1,
        entry_filter = function(entry)
          return require('cmp').lsp.CompletionItemKind.Snippet
            ~= entry:get_kind()
        end,
      },
      {
        name = 'buffer',
        max_item_count = 4,
        keyword_length = 4,
        option = {
          keyword_pattern = [[\k\+]],
          get_bufnrs = function()
            return vim.fn.line2byte(vim.fn.line('$'))
                    + vim.fn.getline('$'):len()
                  > 1048576
                and {}
              or { vim.api.nvim_get_current_buf() }
          end,
        },
      },
    },

    window = {
      completion = {
        winhighlight = 'Normal:CmpFloat,CursorLine:CmpSel',
        side_padding = 1,
        col_offset = 1,
      },
      documentation = {
        border = 'single',
        winhighlight = 'FloatBorder:FloatBorder',
      },
    },
    view = { entries = { name = 'custom', selection_order = 'near_cursor' } },

    formatting = {
      expandable_indicator = true,
      fields = { 'kind', 'abbr', 'menu' },
      format = function(entry, item)
        item.abbr = entry.source.name == 'cmdline' and item.abbr
          or string.sub(item.abbr, 1, 24)
        item.kind = icons[item.kind]
        item.menu = ({
          snippy = 'S',
          nvim_lsp = 'L',
          buffer = 'B',
        })[entry.source.name]
        return item
      end,
    },
  },
  config = function(spec)
    local cmp = require('cmp')
    local opts = vim.tbl_deep_extend('error', spec.opts, {
      mapping = {
        ['<C-l>'] = cmp.mapping.confirm({ select = true }),
        ['<C-k>'] = cmp.mapping.select_prev_item(),
        ['<C-j>'] = cmp.mapping.select_next_item(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-Space>'] = cmp.mapping(require('cmp').mapping.complete()),
      },
      confirm_opts = {
        behavior = cmp.ConfirmBehavior.Replace,
        select = false,
      },
    })

    cmp.setup(opts)
    cmp.setup.cmdline('/', {
      mapping = {
        ['<C-k>'] = { c = cmp.mapping.select_prev_item() },
        ['<C-j>'] = { c = cmp.mapping.select_next_item() },
      },
      sources = { { name = 'buffer' } },
    })
    cmp.setup.cmdline(':', {
      mapping = {
        ['<C-k>'] = { c = cmp.mapping.select_prev_item() },
        ['<C-j>'] = { c = cmp.mapping.select_next_item() },
      },
      sources = cmp.config.sources(
        { { name = 'path' } },
        { { name = 'cmdline' } }
      ),
    })
  end,
}

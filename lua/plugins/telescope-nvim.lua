return {
  'nvim-telescope/telescope.nvim',
  lazy = true,
  cmd = 'Telescope',
  keys = {
    { '<leader>b', '<CMD>Telescope buffers<CR>' },
    { '<leader>ff', '<CMD>Telescope find_files<CR>' },
    { '<leader>fg', '<CMD>silent! Telescope git_files<CR>' },
    { '<leader>rg', '<CMD>Telescope live_grep<CR>' },
    {
      '<leader>ro',
      function()
        require('telescope.builtin').live_grep({ grep_open_files = true })
      end,
    },
    { '<leader>zf', '<CMD>Telescope current_buffer_fuzzy_find<CR>' },
  },
  dependencies = {
    { 'natecraddock/telescope-zf-native.nvim', lazy = true },
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    defaults = {
      initial_mode = 'normal',
      path_display = {
        shorten = { len = 1, exclude = { -2, -1, 1, 2 } },
        truncate = 1,
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '-H',
          '--column',
          '-n',
          '-S',
          '--hidden',
          '--max-depth',
          '8',
        },
      },

      sorting_strategy = 'ascending',
      scroll_strategy = 'limit',
      file_ignore_patterns = { '.cache/', 'undo/' },

      borderchars = {
        prompt = { ' ', ' ', '─', ' ', ' ', ' ', ' ', ' ' },
        results = { ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' },
        preview = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
      },
      layout_strategy = 'flex',
      layout_config = {
        flex = { flip_columns = 120 },

        width = function(_, cols, _)
          return cols
        end,
        height = function(_, _, rows)
          return rows
        end,

        prompt_position = 'top',
        horizontal = {
          preview_cutoff = 10,
          preview_width = 0.5,
        },
        vertical = {
          mirror = true,
          preview_cutoff = 10,
          preview_height = 0.5,
        },
      },

      results_title = false,
      prompt_prefix = ' ',
      entry_prefix = '  ',
      selection_caret = '› ',
      winblend = 0,
      preview = {
        filesize_limit = 0.3,
        timeout = 100,
        hide_on_startup = false,
      },
      color_devicons = true,

      mappings = {
        i = {
          ['<CR>'] = 'select_default',
          ['<C-s>'] = 'select_horizontal',
          ['<C-v>'] = 'select_vertical',
          ['<C-t>'] = 'select_tab',
          ['<C-c>'] = 'close',
          ['<C-j>'] = 'move_selection_next',
          ['<C-k>'] = 'move_selection_previous',
          ['<C-p>'] = function(bufnr)
            require('telescope.actions.layout').toggle_preview(bufnr)
          end,
          ['<C-b>'] = 'preview_scrolling_up',
          ['<C-f>'] = 'preview_scrolling_down',
          ['<C-u>'] = false,
          ['<C-d>'] = false,
          ['<C-q>'] = function(bufnr)
            require('telescope.actions').smart_send_to_qflist(bufnr)
            require('telescope.actions').open_qflist(bufnr)
          end,
        },
        n = {
          ['<ESC>'] = false,
          ['<CR>'] = 'select_default',
          ['<C-s>'] = 'select_horizontal',
          ['<C-v>'] = 'select_vertical',
          ['<C-t>'] = 'select_tab',
          ['<C-c>'] = 'close',
          ['j'] = 'move_selection_next',
          ['k'] = 'move_selection_previous',
          ['gg'] = 'move_to_top',
          ['G'] = 'move_to_bottom',
          ['<C-p>'] = function(bufnr)
            require('telescope.actions.layout').toggle_preview(bufnr)
          end,
          ['<C-b>'] = 'preview_scrolling_up',
          ['<C-f>'] = 'preview_scrolling_down',
          ['<C-u>'] = false,
          ['<C-d>'] = false,
          ['<C-q>'] = function(bufnr)
            require('telescope.actions').smart_send_to_qflist(bufnr)
            require('telescope.actions').open_qflist(bufnr)
          end,
        },
      },
    },

    pickers = {
      cwd = function()
        require('telescope.utils').buffer_dir()
      end,
      hidden = true,

      buffers = {
        initial_mode = 'insert',
        ignore_current_buffer = true,
      },

      find_files = {
        initial_mode = 'insert',
        find_command = { 'fd', '-tf', '-H', '-d10', '--strip-cwd-prefix' },
      },
      git_files = {
        initial_mode = 'insert',
      },

      live_grep = {
        initial_mode = 'insert',
        preview = {
          filesize_limit = 0.3,
          timeout = 100,
        },
      },

      current_buffer_fuzzy_find = {
        initial_mode = 'insert',
        skip_empty_lines = true,
      },
    },

    extensions = {
      ['zf-native'] = {
        file = {
          enable = true,
          highlight_results = true,
          match_filename = true,
        },
        generic = {
          enable = true,
          highlight_results = true,
          match_filename = true,
        },
      },
    },
  },
  config = function(spec)
    require('telescope').setup(spec.opts)
    require('telescope').load_extension('zf-native')
  end,
}

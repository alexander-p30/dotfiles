local util = require('helper.functions')

local function build_keymap(keymap, cmd, desc)
  return { keymap = keymap, cmd = cmd, desc = desc }
end

local telescope_keymaps = {
  build_keymap('<leader><space>', '<cmd>Telescope find_files<CR>', 'Telescope find_files'),
  build_keymap('<leader>f', '<cmd>Telescope live_grep<CR>', 'Telescope live_grep'),
  build_keymap('<leader>b', '<cmd>Telescope buffers<CR>', 'Telescope buffers'),
  build_keymap('<leader>gco', '<cmd>Telescope git_branches<CR>', 'Telescope git_branches'),
  build_keymap('<leader>gcc', '<cmd>Telescope git_commits<CR>', 'Telescope git_commits'),
  build_keymap('<leader>sh', '<cmd>Telescope help_tags<CR>', 'Search through vim help pages'),
  build_keymap('<leader>ss', '<cmd>Telescope persisted<CR>', 'Search through sessions'),
  build_keymap('<leader>cs', '<cmd>Telescope colorscheme<CR>', 'Telescope colorscheme'),
  build_keymap('<leader>nf', '<cmd>Telescope notify<CR>', 'Search notifications'),
  build_keymap('<leader>re', '<cmd>Telescope resume<CR>', 'Resume last query'),
  build_keymap('gr', '<cmd>Telescope lsp_references<CR>', 'LSP go to references'),
  build_keymap('gd', '<cmd>Telescope lsp_definitions<CR>', 'LSP go to definition'),
  build_keymap('gi', '<cmd>Telescope lsp_implementations<CR>', 'LSP go to implementation')
}

local harpoon_keymaps = {
  build_keymap('<leader>ha', function() require("harpoon.mark").add_file() end, 'Add harpoon mark'),
  build_keymap('<leader>hs', function() require("harpoon.ui").toggle_quick_menu() end, 'Show harpoon menu'),
  build_keymap('<leader>h1', function() require("harpoon.ui").nav_file(1) end, 'Open harpoon mark #1'),
  build_keymap('<leader>h2', function() require("harpoon.ui").nav_file(2) end, 'Open harpoon mark #2'),
  build_keymap('<leader>h3', function() require("harpoon.ui").nav_file(3) end, 'Open harpoon mark #3'),
  build_keymap('<leader>h4', function() require("harpoon.ui").nav_file(4) end, 'Open harpoon mark #4'),
  build_keymap('<leader>h5', function() require("harpoon.ui").nav_file(5) end, 'Open harpoon mark #5'),
}

local lazy_load_telescope_keys = util.map(telescope_keymaps, function(_, spec)
  return { spec.keymap, spec.cmd, noremap = true, silent = true, desc = spec.desc }
end)

local lazy_load_harpoon_keys = util.map(harpoon_keymaps, function(_, spec)
  return { spec.keymap, spec.cmd, noremap = true, silent = true, desc = spec.desc }
end)

return {
  {
    'nvim-telescope/telescope.nvim',
    keys = lazy_load_telescope_keys,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-lua/popup.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },

    },
    config = function()
      local previewers = require('telescope.previewers')
      local putils = require('telescope.previewers.utils')
      local pfiletype = require('plenary.filetype')

      local new_maker = function(filepath, bufnr, opts)
        opts = opts or {}
        if opts.use_ft_detect == nil then
          local ft = pfiletype.detect(filepath)
          opts.use_ft_detect = false
          putils.regex_highlighter(bufnr, ft)
        end
        previewers.buffer_previewer_maker(filepath, bufnr, opts)
      end

      require('telescope').setup({
        extensions = {
          fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true, case_mode = 'smart_case' },
        },
        defaults = { buffer_previewer_maker = new_maker, winblend = 15, file_ignore_patterns = { '%.git/' } },
        color_devicons = true,
        pickers = {
          buffers = {
            theme = 'ivy',
            show_all_buffers = true,
            mappings = {
              i = { ['<c-e>'] = 'delete_buffer', },
              n = { ['d'] = 'delete_buffer', ['<c-e>'] = 'delete_buffer' }
            }
          },
          find_files = { theme = 'ivy', hidden = true },
          live_grep = { theme = 'ivy' },
          git_branches = { theme = 'ivy' },
          git_commits = { theme = 'ivy' },
          help_tags = { theme = 'ivy' },
          colorscheme = { theme = 'ivy', enable_preview = true },
          lsp_references = { theme = 'cursor', layout_config = { width = 0.8, height = 0.5 } },
          lsp_definitions = { theme = 'cursor', layout_config = { width = 0.8, height = 0.5 } },
        }
      })

      require('telescope').load_extension('fzf')
      require('telescope').load_extension('persisted')
      require('telescope').load_extension('notify')
    end
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim'
    },
    init = function() vim.g.neo_tree_remove_legacy_commands = 1 end,
    opts = {
      popup_border_style = 'rounded',
      filesystem = {
        hijack_netrw_behavior = 'open_current'
      },
      window = {
        mappings = {
          ['l'] = 'open',
          ['h'] = 'close_node',
          ['c'] = {
            'copy',
            config = {
              show_path = 'relative'
            }
          },
          ['m'] = {
            'move',
            config = {
              show_path = 'relative'
            }
          },
        }
      },
    }
  },
  {
    'ThePrimeagen/harpoon',
    keys = lazy_load_harpoon_keys,
    dependencies = { 'nvim-lua/plenary.nvim' },
  }
}

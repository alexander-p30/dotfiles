local util = require('helper.functions')

local telescope_keymaps = {
  { keymap = '<leader><space>', cmd = '<cmd>Telescope find_files<CR>' },
  { keymap = '<leader>f',       cmd = '<cmd>Telescope live_grep<CR>' },
  { keymap = '<leader>b',       cmd = '<cmd>Telescope buffers<CR>' },
  { keymap = '<leader>gco',     cmd = '<cmd>Telescope git_branches<CR>' },
  { keymap = '<leader>gcc',     cmd = '<cmd>Telescope git_commits<CR>' },
  { keymap = '<leader>sh',      cmd = '<cmd>Telescope help_tags<CR>' },
  { keymap = '<leader>ss',      cmd = '<cmd>Telescope persisted<CR>' },
  { keymap = '<leader>cs',      cmd = '<cmd>Telescope colorscheme<CR>' },
  { keymap = '<leader>nf',      cmd = '<cmd>Telescope notify<CR>' },
}

return {
  {
    'nvim-telescope/telescope.nvim',
    keys = util.map(telescope_keymaps, function(_, spec) return spec.keymap end),
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
              n = { ['d'] = 'delete_buffer',['<c-e>'] = 'delete_buffer' }
            }
          },
          find_files = { theme = 'ivy', hidden = true },
          live_grep = { theme = 'ivy' },
          git_branches = { theme = 'ivy' },
          git_commits = { theme = 'ivy' },
          help_tags = { theme = 'ivy' },
          colorscheme = { theme = 'ivy', enable_preview = true }
        }
      })

      require('telescope').load_extension('fzf')
      require('telescope').load_extension('persisted')
      require('telescope').load_extension('notify')

      local opts = { noremap = true, silent = true }

      for _, spec in pairs(telescope_keymaps) do
        vim.api.nvim_set_keymap('n', spec.keymap, spec.cmd, opts)
      end
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
  }
}

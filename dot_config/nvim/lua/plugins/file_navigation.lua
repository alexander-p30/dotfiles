return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-lua/popup.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      {
        'olimorris/persisted.nvim',
        config = function()
          local util = require('helper.functions')

          require('persisted').setup({
            use_git_branch = true,
            autosave = true,
            autoload = true,
            on_autoload_no_session = function() vim.notify('No existing session to load.') end,
          })

          local group = vim.api.nvim_create_augroup('PersistedHooks', {})

          local hook_specs = {
            { pattern = 'PersistedSavePre', callback = function()
              util.visit_buffers(function(b)
                local buf_ft = vim.api.nvim_buf_get_option(b, 'filetype')
                if buf_ft == 'neo-tree' then vim.api.nvim_buf_delete(b, {}) end
              end)
            end },
            { pattern = 'PersistedSavePost', callback = function() vim.notify('Session saved!') end },
            { pattern = 'PersistedLoadPost', callback = function(session)
              vim.notify('Session loaded! ' .. session.data)
            end },
            { pattern = 'PersistedTelescopeLoadPre', callback = function(_)
              util.visit_buffers(function(b)
                local buf_ft = vim.api.nvim_buf_get_option(b, 'filetype')
                if buf_ft == 'neoterm' then vim.api.nvim_buf_delete(b, { force = true }) end
              end)
            end },
            { pattern = 'PersistedTelescopeLoadPost', callback = function(session)
              vim.notify('Loaded session ' .. session.data.name)
            end }
          }

          for _, hook_spec in pairs(hook_specs) do
            hook_spec.group = group
            vim.api.nvim_create_autocmd({ 'User' }, hook_spec)
          end
        end }

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

      require('telescope').setup {
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
      }

      require('telescope').load_extension('fzf')
      require('telescope').load_extension('persisted')

      local opts = { noremap = true, silent = true }

      vim.api.nvim_set_keymap('n', '<leader><space>', '<cmd>Telescope find_files<CR>', opts)
      vim.api.nvim_set_keymap('n', '<leader>f', '<cmd>Telescope live_grep<CR>', opts)
      vim.api.nvim_set_keymap('n', '<leader>b', '<cmd>Telescope buffers<CR>', opts)
      vim.api.nvim_set_keymap('n', '<leader>gco', '<cmd>Telescope git_branches<CR>', opts)
      vim.api.nvim_set_keymap('n', '<leader>gcc', '<cmd>Telescope git_commits<CR>', opts)
      vim.api.nvim_set_keymap('n', '<leader>sh', '<cmd>Telescope help_tags<CR>', opts)
      vim.api.nvim_set_keymap('n', '<leader>ss', '<cmd>Telescope persisted<CR>', opts)
      vim.api.nvim_set_keymap('n', '<leader>cs', '<cmd>Telescope colorscheme<CR>', opts)
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

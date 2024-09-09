local util = require('helper.functions')

local function build_keymap(keymap, cmd, desc)
  return { keymap = keymap, cmd = cmd, desc = desc }
end

local function telescope_cmd(cmd)
  return '<cmd>Telescope ' .. cmd .. '<CR>'
end

local telescope_keymaps = {
  build_keymap('<leader><space>', telescope_cmd('find_files'), 'Telescope find_files'),
  build_keymap('<leader>f', telescope_cmd('live_grep'), 'Telescope live_grep'),
  build_keymap('<leader>b', telescope_cmd('buffers'), 'Telescope buffers'),
  build_keymap('<leader>gco', telescope_cmd('git_branches'), 'Telescope git_branches'),
  build_keymap('<leader>gcc', telescope_cmd('git_commits'), 'Telescope git_commits'),
  build_keymap('<leader>sh', telescope_cmd('help_tags'), 'Search through vim help pages'),
  build_keymap('<leader>ss', telescope_cmd('persisted'), 'Search through sessions'),
  build_keymap('<leader>cs', telescope_cmd('colorscheme'), 'Telescope colorscheme'),
  build_keymap('<leader>nf', telescope_cmd('notify'), 'Search notifications'),
  build_keymap('<leader>re', telescope_cmd('resume'), 'Resume last query'),
  -- build_keymap('gr', telescope_cmd('lsp_references'), 'LSP go to references'),
  -- build_keymap('gd', telescope_cmd('lsp_definitions'), 'LSP go to definition'),
  -- build_keymap('gi', telescope_cmd('lsp_implementations'), 'LSP go to implementation')
}


local harpoon_keymaps = {
  build_keymap('<leader>ha', function()
    vim.notify('[USER] Added harpoon mark: ' .. vim.fn.expand('%'))
    require('harpoon.mark').add_file()
  end, 'Add harpoon mark'),
  build_keymap('<leader>hs', function() require('harpoon.ui').toggle_quick_menu() end, 'Show harpoon menu')
}

for i = 1, 9 do
  local keymap = build_keymap('<leader>h' .. i, function() require('harpoon.ui').nav_file(i) end,
    'Open harpoon mark #' .. i)
  table.insert(harpoon_keymaps, keymap)
end


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
      'neovim/nvim-lspconfig'
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
          lsp_references = {
            theme = 'dropdown',
            fname_width = 80,
            path_display = { shorten = 7 },
            layout_config = { width = 0.8, height = 0.5 }
          },
          lsp_definitions = {
            theme = 'dropdown',
            fname_width = 80,
            path_display = { shorten = 7 },
            layout_config = { width = 0.8, height = 0.5 }
          },
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
    branch = "v3.x",
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

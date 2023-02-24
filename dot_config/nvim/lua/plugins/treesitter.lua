return {
  'nvim-treesitter/nvim-treesitter',
  build = function()
    pcall(require('nvim-treesitter.install').update { with_sync = true })
  end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    {
      'ustrajunior/ex_maps',
      opts = { create_mappings = true, mapping = 'mtt' },
      ft = { 'elixir', 'eelixir', 'heex' }
    },
  },
  config = function()
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
        'help', 'elixir', 'heex', 'ruby', 'html', 'javascript', 'c', 'cpp', 'go', 'haskell', 'java',
        'lua', 'bash', 'erlang', 'sql', 'clojure', 'cmake', 'dockerfile', 'fennel', 'http', 'json',
        'json5', 'jsonc', 'make', 'org', 'python', 'rasi', 'typescript', 'tsx', 'yaml'
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<c-space>',
          node_incremental = '<c-space>',
          node_decremental = '<c-backspace>',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ab'] = '@block.outer',
            ['ib'] = '@block.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = { [']f'] = '@function.outer',[']b'] = '@block.outer' },
          goto_next_end = { [']F'] = '@function.outer',[']B'] = '@block.outer' },
          goto_previous_start = { ['[f'] = '@function.outer',['[b'] = '@block.outer' },
          goto_previous_end = { ['[F'] = '@function.outer',['[B'] = '@block.outer' },
        },
        swap = {
          enable = true,
          swap_next = {
            ['<leader>a'] = '@parameter.inner',
          },
          swap_previous = {
            ['<leader>A'] = '@parameter.inner',
          },
        },
      }
    })

    -- highlight rascal files as java
    local ft_to_parser = require 'nvim-treesitter.parsers'.filetype_to_parsername
    ft_to_parser.routeros = 'java'
  end
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = function()
      pcall(require('nvim-treesitter.install').update { with_sync = true })
    end,
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'elixir', 'heex', 'ruby', 'html', 'javascript', 'c', 'cpp', 'go', 'haskell', 'java',
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
            goto_next_start = { [']f'] = '@function.outer', [']b'] = '@block.outer' },
            goto_next_end = { [']F'] = '@function.outer', [']B'] = '@block.outer' },
            goto_previous_start = { ['[f'] = '@function.outer', ['[b'] = '@block.outer' },
            goto_previous_end = { ['[F'] = '@function.outer', ['[B'] = '@block.outer' },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>sa'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>sA'] = '@parameter.inner',
            },
          },
        },
        endwise = { enable = true }
      })
    end
  },
  {
    'RRethy/nvim-treesitter-endwise',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'ruby', 'elixir', 'eelixir', 'heex', 'lua', 'bash' }
  },
  {
    'ustrajunior/ex_maps',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = { create_mappings = true, mapping = 'mtt' },
    ft = { 'elixir', 'eelixir', 'heex' }
  }
}

require 'nvim-treesitter.configs'.setup {
  ensure_installed = { 'elixir', 'ruby', 'html', 'javascript', 'c', 'cpp', 'go', 'haskell', 'java', 'lua', 'bash',
    'erlang', 'sql', 'clojure', 'cmake', 'dockerfile', 'fennel', 'http', 'json', 'json5', 'jsonc', 'make', 'org',
    'python', 'rasi', 'typescript', 'tsx', 'yaml' },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true,
  },
  rainbow = {
    enable = true,
    extended_mode = true,
    max_file_lines = nil,
    -- colors = { '#f2594b', '#e9b143', '#b0b846', '#8bba7f', '#80aa9e', '#d3869b' }
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
        ['<leader>a'] = '@parameter.inner',
      },
      swap_previous = {
        ['<leader>A'] = '@parameter.inner',
      },
    },
  }
}

-- highlight rascal files as java
local ft_to_parser = require 'nvim-treesitter.parsers'.filetype_to_parsername
ft_to_parser.routeros = 'java'

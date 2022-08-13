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
    colors = { '#f2594b', '#e9b143', '#b0b846', '#8bba7f', '#80aa9e', '#d3869b' }
  },
}

-- highlight rascal files as java
local ft_to_parser = require 'nvim-treesitter.parsers'.filetype_to_parsername
ft_to_parser.routeros = 'java'

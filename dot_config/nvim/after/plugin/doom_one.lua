local config = {
  cursor_coloring = true,
  terminal_colors = true,
  italic_comments = false,
  enable_treesitter = true,
  transparent_background = false,
  pumblend = {
    enable = true,
    transparency_amount = 20,
  },
  plugins_integrations = {
    telescope = true,
    whichkey = true,
    indent_blankline = true,
    vim_illuminate = true,
  },
}

if vim.g.colors_name == 'doom-one' then require('doom-one').setup(config) end

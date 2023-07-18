return {
  { 'navarasu/onedark.nvim',        event = 'VeryLazy' },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    event = 'VeryLazy',
    opts = {
      transparent_background = false,
      term_colors = true,
      flavour = 'mocha',
      integrations = {
        neotree = false,
        cmp = true,
        illuminate = true,
        telescope = true
      },
      highlight_overrides = {
        all = function(colors)
          return {
            DiagnosticFloatingError = { fg = colors.red, bg = colors.none },
            DiagnosticFloatingWarn = { fg = colors.yellow, bg = colors.none },
            DiagnosticFloatingInfo = { fg = colors.sky, bg = colors.none },
            DiagnosticFloatingHint = { fg = colors.teal, bg = colors.none },
          }
        end
      }
    }
  },
  {
    'folke/tokyonight.nvim',
    event = 'VeryLazy',
    opts = { style = 'moon', terminal_colors = false }
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    event = 'VeryLazy',
    opts = {
      char = '|',
      buftype_exclude = { 'terminal' },
      show_current_context = true,
    }
  },
  {
    'rcarriga/nvim-notify',
    config = function() vim.notify = require('notify') end,
  },
  { 'nvim-tree/nvim-web-devicons',  opts = { default = true } },
  { 'stevearc/dressing.nvim',       event = 'VeryLazy' },
  { 'nvim-zh/colorful-winsep.nvim', opts = { highlight = { bg = '' } } }
}

return {
  { 'navarasu/onedark.nvim',       lazy = true },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
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
    },
    lazy = true
  },
  {
    'folke/tokyonight.nvim',
    opts = { style = 'moon', terminal_colors = false },
    lazy = true
  },
  { 'lukas-reineke/indent-blankline.nvim',
    opts = {
      char = '|',
      buftype_exclude = { 'terminal' },
      show_current_context = true, }
  },
  { 'rcarriga/nvim-notify',        config = function() vim.notify = require('notify') end },
  { 'norcalli/nvim-colorizer.lua', config = true },
  { 'nvim-tree/nvim-web-devicons', opts = { default = true } },
  'MunifTanjim/nui.nvim',
  'stevearc/dressing.nvim',
  { 'nvim-zh/colorful-winsep.nvim', opts = { highlight = { bg = '' } } }
}

return {
  'nyoom-engineering/oxocarbon.nvim',
  'ellisonleao/gruvbox.nvim',
  'navarasu/onedark.nvim',
  { 'bluz71/vim-moonfly-colors',    name = 'moonfly' },
  'kvrohit/rasmus.nvim',
  'ishan9299/modus-theme-vim',
  {
    'mcchrish/zenbones.nvim',
    dependencies = { 'rktjmp/lush.nvim' }
  },
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
    }
  },
  {
    'folke/tokyonight.nvim',
    opts = { style = 'moon', terminal_colors = false }
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {}
  },
  {
    'rcarriga/nvim-notify',
    config = function() vim.notify = require('notify') end,
  },
  { 'nvim-tree/nvim-web-devicons',  opts = { default = true } },
  { 'stevearc/dressing.nvim',       event = 'VeryLazy' },
  { 'nvim-zh/colorful-winsep.nvim', opts = { highlight = { bg = '' } } }
}

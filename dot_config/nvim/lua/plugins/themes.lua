local util = require('helper.functions')

local theme = function(spec)
  local defaults = {
    priority = 1000,
    lazy = false
  }

  return util.merge_tables(defaults, util.table_wrap(spec))
end

return {
  theme 'projekt0n/github-nvim-theme',
  theme 'nyoom-engineering/oxocarbon.nvim',
  theme 'ellisonleao/gruvbox.nvim',
  theme 'navarasu/onedark.nvim',
  theme { 'bluz71/vim-moonfly-colors', name = 'moonfly' },
  theme 'kvrohit/rasmus.nvim',
  theme 'ishan9299/modus-theme-vim',
  theme {
    'mcchrish/zenbones.nvim',
    dependencies = { 'rktjmp/lush.nvim' },
  },
  theme {
    'catppuccin/nvim',
    name = 'catppuccin',
    opts = {
      transparent_background = false,
      term_colors = true,
      flavour = 'mocha',
      integrations = {
        neotree = true,
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
  theme {
    'folke/tokyonight.nvim',
    opts = { style = 'moon', terminal_colors = false }
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
    init = function()
      vim.api.nvim_set_hl(0, 'IblScope', { fg = '#BABBC2', bold = false })
    end
  },
  {
    'rcarriga/nvim-notify',
    config = function() vim.notify = require('notify') end,
  },
  { 'nvim-tree/nvim-web-devicons',  opts = { default = true } },
  { 'stevearc/dressing.nvim',       event = 'VeryLazy' },
  { 'nvim-zh/colorful-winsep.nvim', opts = { animate = { enabled = false } } }
}

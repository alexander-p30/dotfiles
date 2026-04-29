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
      vim.api.nvim_set_hl(0, 'IblIndent', { fg = '#4A4B52', bold = false })
      vim.api.nvim_set_hl(0, 'IblScope', { fg = '#BABBC2', bold = false })
    end
  },
  {
    'nvim-mini/mini.notify',
    version = '*',
    config = function()
      require('mini.notify').setup({
        content = {
          format = function(notif)
            local level_names = {
              [vim.log.levels.ERROR] = 'ERROR',
              [vim.log.levels.WARN]  = 'WARN',
              [vim.log.levels.INFO]  = 'INFO',
              [vim.log.levels.DEBUG] = 'DEBUG',
              [vim.log.levels.TRACE] = 'TRACE',
            }
            local level = level_names[notif.level] or 'INFO'
            local time = os.date('%H:%M:%S', math.floor(notif.ts_add))
            return ('%s  [%s]  %s\n%s'):format(time, level, notif.msg, string.rep('─', 40))
          end,
        },
      })
      vim.notify = require('mini.notify').make_notify()
    end,
  },
  { 'nvim-tree/nvim-web-devicons', opts = { default = true } },
  { 'stevearc/dressing.nvim',      event = 'VeryLazy' }
}

local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  Packer_bootstrap = fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim',
    install_path })
  vim.cmd [[packadd packer.nvim]]
end

return require('packer').startup({ function(use)
  use 'wbthomason/packer.nvim'

  -- File-navigation
  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'nvim-lua/popup.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
    }
  }
  use 'nvim-neo-tree/neo-tree.nvim'

  -- Fonts and assets
  use 'lambdalisue/nerdfont.vim'

  -- Git
  use 'lewis6991/gitsigns.nvim'
  use 'tpope/vim-fugitive'

  -- LS, syntax highlighting and programming utils
  use {
    {
      'williamboman/mason.nvim',
      config = function() require('mason').setup({ ui = { border = 'rounded' } }) end
    },
    {
      'williamboman/mason-lspconfig.nvim',
      config = function() require("mason-lspconfig").setup({ automatic_installation = true }) end
    },
    "neovim/nvim-lspconfig"
  }
  use {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/nvim-cmp',
    {
      'saadparwaiz1/cmp_luasnip',
      config = function() require('luasnip.loaders.from_snipmate').lazy_load() end,
    },
    'L3MON4D3/LuaSnip'
  }
  use 'ray-x/lsp_signature.nvim'
  use 'onsails/lspkind-nvim'
  use 'vim-test/vim-test'
  use 'elixir-editors/vim-elixir'
  use {
    "windwp/nvim-autopairs",
    config = function() require("nvim-autopairs").setup {} end
  }
  use 'tpope/vim-surround'
  use 'tpope/vim-commentary'
  use {
    'tpope/vim-endwise',
    ft = { 'ruby', 'elixir', 'eelixir' },
    commit = '9471eeb'
  }
  use 'mg979/vim-visual-multi'
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    'p00f/nvim-ts-rainbow',
    {
      'nvim-treesitter/playground',
      cmd = { 'TSPlaygroundToggle', 'TSHighlightCapturesUnderCursor' },
    },
  }
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    after = 'nvim-treesitter',
  }
  use { 'neovimhaskell/haskell-vim', ft = 'haskell' }
  use { 'mboughaba/i3config.vim', ft = 'i3config' }
  use 'fladson/vim-kitty'
  use 'RRethy/vim-illuminate'
  use 'kmonad/kmonad-vim'
  use { 'Olical/conjure', ft = 'clojure' }
  use 'rust-lang/rust.vim'
  use {
    'gelguy/wilder.nvim',
    config = function()
      local wilder = require('wilder')
      wilder.setup({ modes = { ':', '/', '?' } })
      wilder.set_option('renderer', wilder.popupmenu_renderer(
        wilder.popupmenu_border_theme({
          highlights = { border = 'Normal', },
          border = 'rounded',
        })
      ))
    end,
  }
  use 'tpope/vim-sleuth'

  -- Projectionist
  use 'tpope/vim-projectionist'
  use 'c-brenn/fuzzy-projectionist.vim'
  use 'andyl/vim-projectionist-elixir'

  -- Other
  use 'kassio/neoterm'
  use 'olimorris/persisted.nvim'
  use 'simeji/winresizer'
  use {
    'ustrajunior/ex_maps',
    config = function()
      require('ex_maps').setup { create_mappings = true, mapping = 'mtt' }
    end
  }
  use { 'rcarriga/nvim-notify', config = function() vim.notify = require('notify') end }
  use { 'mbbill/undotree' }

  -- Themes / Visual
  use 'navarasu/onedark.nvim'
  use {
    'catppuccin/nvim',
    as = 'catppuccin',
    config = function()
      require('catppuccin').setup({
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
      })
      vim.api.nvim_command('colorscheme catppuccin')
    end
  }
  use { 'norcalli/nvim-colorizer.lua', config = function() require('colorizer').setup() end }
  use { 'j-hui/fidget.nvim', config = function() require('fidget').setup() end }
  use {
    'folke/tokyonight.nvim',
    config = function()
      require("tokyonight").setup({ style = "moon", terminal_colors = false })
    end
  }
  use {
    'kyazdani42/nvim-web-devicons',
    config = function()
      require 'nvim-web-devicons'.setup { default = true }
    end
  }
  use 'nvim-lualine/lualine.nvim'
  use 'NTBBloodbath/doom-one.nvim'
  use 'lukas-reineke/indent-blankline.nvim'
  use 'MunifTanjim/nui.nvim'
  use 'stevearc/dressing.nvim'
  --
  if Packer_bootstrap then
    require('packer').sync()
  end
end,
  config = {
    -- snapshot = '12082022.json'
  } })

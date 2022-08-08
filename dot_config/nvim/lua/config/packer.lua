local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  Packer_bootstrap = fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim',
    install_path })
  vim.cmd [[packadd packer.nvim]]
end

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- File-related
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
  use 'airblade/vim-gitgutter'
  use 'APZelos/blamer.nvim'
  use 'tpope/vim-fugitive'

  -- LS, syntax highlighting and programming utils
  use {
    'neovim/nvim-lspconfig',
    'williamboman/nvim-lsp-installer'
  }
  use {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/nvim-cmp',
    {
      'saadparwaiz1/cmp_luasnip',
      config = function()
        require('luasnip.loaders.from_snipmate').lazy_load()
      end,
    },
    'L3MON4D3/LuaSnip'
  }
  use 'ray-x/lsp_signature.nvim'
  use 'onsails/lspkind-nvim'
  use 'vim-test/vim-test'
  use 'elixir-editors/vim-elixir'
  use 'rstacruz/vim-closer'
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
  use { 'neovimhaskell/haskell-vim', ft = 'haskell' }
  use { 'mboughaba/i3config.vim', ft = 'i3config' }
  use 'fladson/vim-kitty'
  use 'RRethy/vim-illuminate'
  use 'kmonad/kmonad-vim'
  use { 'tversteeg/registers.nvim', branch = 'main' }
  use { 'Olical/conjure', ft = 'clojure' }
  use { 'fatih/vim-go', run = ':GoUpdateBinaries' }
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

  -- Projectionist
  use 'tpope/vim-projectionist'
  use 'c-brenn/fuzzy-projectionist.vim'
  use 'andyl/vim-projectionist-elixir'

  -- Other
  use 'kassio/neoterm'
  use 'antoinemadec/FixCursorHold.nvim'
  use 'olimorris/persisted.nvim'
  use 'simeji/winresizer'
  use {
    'ustrajunior/ex_maps',
    config = function()
      require('ex_maps').setup { create_mappings = true, mapping = 'mtt' }
    end
  }

  -- Themes / Visual
  use 'navarasu/onedark.nvim'
  use {
    'catppuccin/nvim',
    as = 'catppuccin',
    config = function()
      require('catppuccin').setup({
        transparent_background = true,
        term_colors = true,
        integrations = { telescope = true }
      })
    end
  }
  use 'norcalli/nvim-colorizer.lua'
  use 'folke/tokyonight.nvim'
  use {
    'kyazdani42/nvim-web-devicons',
    config = function()
      require 'nvim-web-devicons'.setup { default = true }
    end
  }
  use 'nvim-lualine/lualine.nvim'
  use 'NTBBloodbath/doom-one.nvim'
  use 'lukas-reineke/indent-blankline.nvim'
  use 'folke/which-key.nvim'
  use 'MunifTanjim/nui.nvim'
  --
  if Packer_bootstrap then
    require('packer').sync()
  end
end)

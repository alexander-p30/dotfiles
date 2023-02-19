local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- File-navigation
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-lua/popup.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    }
  },
  { 'nvim-neo-tree/neo-tree.nvim', cmd = 'Neotree' },

  -- Fonts and assets
  'lambdalisue/nerdfont.vim',

  -- Git
  'lewis6991/gitsigns.nvim',
  { 'tpope/vim-fugitive',          cmd = 'Git' },

  -- LS, syntax highlighting and programming utils
  {
    {
      'williamboman/mason.nvim',
      config = function() require('mason').setup({ ui = { border = 'rounded' } }) end
    },
    {
      'williamboman/mason-lspconfig.nvim',
      config = function() require("mason-lspconfig").setup({ automatic_installation = true }) end
    },
    "neovim/nvim-lspconfig"
  },
  {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/nvim-cmp',
    'SirVer/ultisnips',
    'quangnguyen30192/cmp-nvim-ultisnips'
  },
  'ray-x/lsp_signature.nvim',
  'onsails/lspkind-nvim',
  'vim-test/vim-test',
  { 'elixir-editors/vim-elixir', ft = { 'elixir', 'eelixir', 'heex' } },
  { "windwp/nvim-autopairs",     config = true },
  'tpope/vim-surround',
  'tpope/vim-commentary',
  { 'tpope/vim-endwise',         ft = { 'ruby', 'elixir', 'eelixir', 'heex' } },
  'mg979/vim-visual-multi',
  {
    'nvim-treesitter/nvim-treesitter',
    build = function()
      pcall(require('nvim-treesitter.install').update { with_sync = true })
    end,
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
  },
  'RRethy/vim-illuminate',
  { 'neovimhaskell/haskell-vim', ft = 'haskell' },
  { 'mboughaba/i3config.vim',    ft = 'i3config' },
  { 'fladson/vim-kitty',         ft = 'kitty' },
  { 'kmonad/kmonad-vim',         ft = 'kbd' },
  { 'Olical/conjure',            ft = 'clojure' },
  { 'rust-lang/rust.vim',        ft = 'rust' },
  {
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
  },

  -- Projectionist
  'tpope/vim-projectionist',
  'c-brenn/fuzzy-projectionist.vim',
  'andyl/vim-projectionist-elixir',

  -- Other
  'kassio/neoterm',
  'olimorris/persisted.nvim',
  'simeji/winresizer',
  {
    'ustrajunior/ex_maps',
    config = { create_mappings = true, mapping = 'mtt' },
    ft = { 'elixir', 'eelixir', 'heex' }
  },
  { 'rcarriga/nvim-notify',  config = function() vim.notify = require('notify') end },
  'mbbill/undotree',

  -- Themes / Visual
  { 'navarasu/onedark.nvim', lazy = true },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    config = {
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
  { 'norcalli/nvim-colorizer.lua', config = true },
  { 'j-hui/fidget.nvim',           config = true },
  {
    'folke/tokyonight.nvim',
    config = { style = "moon", terminal_colors = false },
    lazy = true
  },
  { 'nvim-tree/nvim-web-devicons', config = { default = true } },
  'nvim-lualine/lualine.nvim',
  { 'NTBBloodbath/doom-one.nvim',  lazy = true },
  { 'lukas-reineke/indent-blankline.nvim', config = {
    char = '|',
    buftype_exclude = { 'terminal' },
    show_current_context = true, }
  },
  'MunifTanjim/nui.nvim',
  'stevearc/dressing.nvim',
  --
})

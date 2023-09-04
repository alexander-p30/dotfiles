return {
  { 'elixir-editors/vim-elixir', ft = { 'ex', 'elixir', 'eex', 'heex', 'surface' } },
  { 'neovimhaskell/haskell-vim', ft = 'haskell' },
  { 'mboughaba/i3config.vim',    ft = 'i3config' },
  { 'fladson/vim-kitty',         ft = 'kitty' },
  { 'kmonad/kmonad-vim',         ft = 'kbd' },
  { 'Olical/conjure',            ft = 'clojure' },
  { 'rust-lang/rust.vim',        ft = 'rust' },
  {
    'elixir-tools/elixir-tools.nvim',
    enabled = false,
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  {
    'mhartington/formatter.nvim',
    ft = { 'ex', 'elixir', 'eex', 'heex', 'surface' },
    config = function()
      require('formatter').setup({
        logging = true,
        log_level = vim.log.levels.WARN,
        filetype = {
          elixir = {
            require('formatter.filetypes.elixir').mixformat,
          },
        },
      })
    end
  }
}

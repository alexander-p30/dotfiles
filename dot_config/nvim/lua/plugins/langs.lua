return {
  { 'elixir-editors/vim-elixir', ft = { 'elixir', 'eelixir', 'heex' } },
  { 'neovimhaskell/haskell-vim', ft = 'haskell' },
  { 'mboughaba/i3config.vim',    ft = 'i3config' },
  { 'fladson/vim-kitty',         ft = 'kitty' },
  { 'kmonad/kmonad-vim',         ft = 'kbd' },
  { 'Olical/conjure',            ft = 'clojure' },
  { 'rust-lang/rust.vim',        ft = 'rust' },
  {
    'elixir-tools/elixir-tools.nvim',
    ft = { 'elixir', 'eex', 'heex', 'surface' },
    config = function()
      local elixir = require('elixir')

      elixir.setup({
        credo = { enabled = true },
        elixirls = { enabled = false }
      })
    end,
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  }
}

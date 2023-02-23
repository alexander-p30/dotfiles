return {
  {
    'vim-test/vim-test',
    config = function()
      vim.g['test#strategy'] = 'neoterm'
    end
  },
  'tpope/vim-surround',
  'tpope/vim-commentary',
  { 'tpope/vim-endwise', ft = { 'ruby', 'elixir', 'eelixir', 'heex' } },
  'mg979/vim-visual-multi',
  'RRethy/vim-illuminate',
  {
    'kassio/neoterm',
    config = function()
      vim.g.neoterm_default_mod = 'botright'
      vim.g.neoterm_size = ''
      vim.g.neoterm_autoscroll = 1
      vim.g.neoterm_automap_keys = ''
    end
  },
  'simeji/winresizer',
  'mbbill/undotree'
}

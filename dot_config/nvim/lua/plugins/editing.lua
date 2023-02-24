return {
  {
    'vim-test/vim-test',
    cmd = { 'TestNearest', 'TestFile', 'TestSuite', 'TestLast' },
    init = function()
      vim.g['test#strategy'] = 'neoterm'
    end
  },
  {
    'tpope/vim-surround',
    keys = { 'cs', 'ys', 'ds', { 'S', mode = 'v' } }
  },
  {
    'numToStr/Comment.nvim',
    keys = {
      { 'gc', mode = { 'n', 'v' } },
      { 'gb', mode = { 'n', 'v' } }
    },
    config = true
  },
  { 'tpope/vim-endwise',      ft = { 'ruby', 'elixir', 'eelixir', 'heex' } },
  { 'mg979/vim-visual-multi', keys = { { '<C-n>', mode = 'v' }, '<C-down>' } },
  { 'RRethy/vim-illuminate',  event = 'VeryLazy' },
  {
    'kassio/neoterm',
    init = function()
      vim.g.neoterm_default_mod = 'botright'
      vim.g.neoterm_size = ''
      vim.g.neoterm_autoscroll = 1
      vim.g.neoterm_automap_keys = ''
    end
  },
  { 'simeji/winresizer',    keys = '<C-e>' },
  { 'mbbill/undotree',      cmd = 'UndotreeToggle' },
  { 'folke/which-key.nvim', config = true }
}

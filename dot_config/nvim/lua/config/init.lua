require('config.packer')
require('config.autocmds')
require('config.functions')
require('config.keymap')
require('config.opts')

-- vim-test
vim.g['test#strategy'] = 'neoterm'

-- neoterm
vim.g.neoterm_default_mod = 'botright'
vim.g.neoterm_size = ''
vim.g.neoterm_autoscroll = 1
vim.g.neoterm_automap_keys = ''

-- theme
vim.cmd('highlight LineNr guifg=#9ca0a4')

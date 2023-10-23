require('config.opts')
require('config.lazy')
require('config.autocmds')
require('config.keymap')

vim.cmd([[
silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)
]])
vim.cmd.colorscheme('tokyobones')
vim.cmd.highlight('LineNr guifg=#9ca0a4')

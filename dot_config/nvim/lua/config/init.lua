require('config.packer')
require('config.autocmds')
require('config.functions')
require('config.keymap')
require('config.opts')

-- vim-test
vim['test#strategy'] = 'neoterm'

-- neoterm
vim.g.neoterm_default_mod = 'botright'
vim.g.neoterm_size = ''
vim.g.neoterm_autoscroll = 1
vim.g.neoterm_automap_keys = ''

-- gitgutter
local gitgutter_character = "▋"
vim.g.gitgutter_sign_added = gitgutter_character
vim.g.gitgutter_sign_modified = gitgutter_character
vim.g.gitgutter_sign_removed = gitgutter_character
vim.g.gitgutter_sign_removed_first_line = gitgutter_character
vim.g.gitgutter_sign_removed_above_and_below = gitgutter_character
vim.g.gitgutter_sign_modified_removed = gitgutter_character

-- git-blamer
vim.g.blamer_enabled = 1
vim.g.blamer_show_in_visual_modes = 0
vim.g.blamer_delay = 500
vim.g.blamer_prefix = ' 🤡 '

-- theme
vim.g.catppuccin_flavour = "mocha" -- latte, frappe, macchiato, mocha
vim.cmd.colorscheme('catppuccin')
vim.cmd('highlight LineNr guifg=#9ca0a4')

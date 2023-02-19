local opt = vim.opt

-- MAPLEADER
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Folding {{{
opt.foldenable = false
opt.foldmethod = 'expr'
opt.foldexpr = 'nvim_treesitter#foldexpr()'
-- }}}

-- General Sets and Cmds {{{
-- Indentation
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Timing
opt.timeoutlen = 1000
opt.updatetime = 250

-- Dinamically loaded vim configs
opt.exrc = true

-- Text editing
-- Line information
opt.relativenumber = true
opt.number = true

opt.wrap = false

-- Swap and backup
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
opt.undofile = true
opt.hidden = true

-- trigger `autoread` when files changes on disk
opt.autoread = true

opt.title = true
opt.incsearch = true
opt.scrolloff = 4
opt.completeopt = { 'menuone', 'noinsert', 'noselect' }
opt.signcolumn = 'yes'
opt.colorcolumn = { 100, 120 }
opt.cursorline = true
opt.termguicolors = true

-- Split behaviour
opt.equalalways = false
opt.splitbelow = true
opt.splitright = true
-- }}}

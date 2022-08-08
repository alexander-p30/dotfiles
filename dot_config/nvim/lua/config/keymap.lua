local nmap = require('config.remap').nmap
local nnoremap = require('config.remap').nnoremap
local vnoremap = require('config.remap').vnoremap
local tnoremap = require('config.remap').tnoremap
local util = require('config.functions')

-- MAPLEADER
vim.g.mapleader = ' '

-- Add {count}k and {count}j to jumplist
vim.cmd([[
nnoremap <expr> k (v:count > 1 ? "m'" . v:count : '') . 'k'
nnoremap <expr> j (v:count > 1 ? "m'" . v:count : '') . 'j'
]])

-- Terminal/test-related bindings {{{
nnoremap('<leader>tt', ':Ttoggle<CR>', { silent = true })
nnoremap('<leader>alt', ':A<CR>')

nnoremap('<leader>tn', '', { callback = function() util.test_in_neoterm('tn') end })
nnoremap('<leader>tf', '', { callback = function() util.test_in_neoterm('tf') end })
nnoremap('<leader>ts', '', { callback = function() util.test_in_neoterm('ts') end })
nnoremap('<leader>tl', '', { callback = function() util.test_in_neoterm('tl') end })

nnoremap('<leader>tv', ':TestVisit<CR>')
nnoremap('<leader>tc', ':Tclose!<CR>')
-- }}}

-- Tabs {{{
nnoremap('<leader>tan', ':tabedit %<CR> ', { silent = true })
nnoremap('<leader>taN', ':tabnew<CR>', { silent = true })
nnoremap('<leader>taO', ':tabonly<CR>', { silent = true })
nnoremap('<leader>tac', ':tabclose<CR>', { silent = true })
nnoremap('<leader>tal', ':tabnext<CR>', { silent = true })
nnoremap('<leader>tah', ':tabprevious<CR>', { silent = true })

nnoremap('<leader>ta1', '1gt', { silent = true })
nnoremap('<leader>ta2', '2gt', { silent = true })
nnoremap('<leader>ta3', '3gt', { silent = true })
nnoremap('<leader>ta4', '4gt', { silent = true })
nnoremap('<leader>ta5', '5gt', { silent = true })
nnoremap('<leader>ta6', '6gt', { silent = true })
nnoremap('<leader>ta7', '7gt', { silent = true })
nnoremap('<leader>ta8', '8gt', { silent = true })
nnoremap('<leader>ta9', '9gt', { silent = true })
-- }}}

-- Linting {{{
nnoremap('<leader>cq', '', { callback = function() util.lint_in_neoterm() end })
-- }}}

-- Yanking and pasting clipboard {{{
vnoremap('<C-y>', '"+y')
nnoremap('<C-p>', '"+p')
vnoremap('<C-p>', '"+p')
-- }}}

-- Writing and Closing {{{
nnoremap('<leader>w', ':w<CR>')
nnoremap('<leader>qw', ':wq<CR>')
nnoremap('<leader>qq', ':q<CR>', { silent = true })
nnoremap('<leader>qall', ':qall<CR>')
nnoremap('<leader>qal!', ':qall!<CR>')
nnoremap('<leader>Q', ':q!<CR>', { silent = true })
-- }}}

-- Neotree {{{
nnoremap('<C-b>', ':Neotree toggle=true reveal<CR>', { silent = true })
-- }}}

-- Copy until end of line
nnoremap('Y', 'y$')

-- Copy current filepath
nmap('<leader>yfp', ':let @" = expand("%")<CR>')

-- Clear search highlighting
nnoremap('<C-h>', ':noh<CR>', { silent = true })

-- Reparse buffers
nnoremap('<leader>rt', ':write | edit | TSBufEnable highlight<CR>', { silent = true })

-- Update configs
nnoremap('<leader>re', '', {
  silent = true,
  callback = function()
    vim.api.nvim_command('SessionSave')
    vim.api.nvim_command('luafile ' .. os.getenv('HOME') .. '/.config/nvim/init.lua')
  end
})

-- gitgutter hunk navigation
nnoremap('<CR>', ':GitGutterNextHunk<CR>', { silent = true })
nnoremap('<backspace>', ':GitGutterPrevHunk<CR>', { silent = true })

-- Git
nnoremap('<leader>gg', ':Git<CR>', { silent = true })
nnoremap('<leader>gP', ':Git push<CR>')
nnoremap('<leader>gsP', ':Git push -u origin HEAD')
nnoremap('<leader>gp', ':Git pull<CR>')
nnoremap('<leader>gcb', ':Git checkout -b ')
nnoremap('<leader>gc-', ':Git checkout -')
nnoremap('<leader>gbD', ':Git branch -D')

-- Delete all buffers
nnoremap('<leader>db', ':%bd <bar> e#')
nnoremap('<leader>dab', ':%bd')

-- Increment number under the cursor
nnoremap('<C-s>', '<C-a>')

-- Sort selection
vnoremap('<leader>so', ':\'<,\'>sort<CR>', { silent = true })

-- Move visual selection
vnoremap('<Up>', ':m \'<-2<CR>gv=gv')
vnoremap('<Down>', ':m \'>+1<CR>gv=gv')

-- Quickfix list navigation
nnoremap('<leader>cn', ':cnext <CR>')
nnoremap('<leader>cp', ':cprev <CR>')
nnoremap('<leader>co', ':copen <CR>', { silent = true })
nnoremap('<leader>cc', ':cc <CR>', { silent = true })
nnoremap('<leader>cC', ':cclose <CR>', { silent = true })

-- Location list navigation
nnoremap('<leader>ln', ':lnext <CR>')
nnoremap('<leader>lp', ':lprev <CR>')
nnoremap('<leader>lo', ':lopen <CR>', { silent = true })
nnoremap('<leader>lc', ':lc <CR>', { silent = true })
nnoremap('<leader>lC', ':lclose <CR>', { silent = true })
-- }}}

-- Esc to leave terminal mode
tnoremap('<Esc>', '<C-\\><C-n>')

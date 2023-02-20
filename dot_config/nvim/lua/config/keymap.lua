local nmap = require('config.remap').nmap
local nnoremap = require('config.remap').nnoremap
local vnoremap = require('config.remap').vnoremap
local tnoremap = require('config.remap').tnoremap
local util = require('config.functions')

-- Centralize cursor on vertical movement
nnoremap('<C-d>', '<C-d>zz')
nnoremap('<C-u>', '<C-u>zz')
nnoremap('n', 'nzzzv')
nnoremap('N', 'Nzzzv')

-- Add {count}k and {count}j to jumplist
vim.cmd([[
nnoremap <expr> k (v:count > 1 ? "m'" . v:count : '') . 'k'
nnoremap <expr> j (v:count > 1 ? "m'" . v:count : '') . 'j'
]])

-- Terminal/test-related bindings {{{
nnoremap('<leader>tt', vim.cmd.Ttoggle, { silent = true })
nnoremap('<leader>alt', ':A<CR>')

nnoremap('<leader>tn', function() util.test_in_neoterm('tn') end)
nnoremap('<leader>tf', function() util.test_in_neoterm('tf') end)
nnoremap('<leader>ts', function() util.test_in_neoterm('ts') end)
nnoremap('<leader>tl', function() util.test_in_neoterm('tl') end)

nnoremap('<leader>tv', vim.cmd.TestVisit)
nnoremap('<leader>tc', ':Tclose!<CR>')
-- }}}

-- Tabs {{{
nnoremap('<leader>tan', ':tabedit %<CR>', { silent = true })
nnoremap('<leader>taN', vim.cmd.tabnew, { silent = true })
nnoremap('<leader>taO', vim.cmd.tabonly, { silent = true })
nnoremap('<leader>tac', vim.cmd.tabclose, { silent = true })
nnoremap('<leader>tal', vim.cmd.tabnext, { silent = true })
nnoremap('<leader>tah', vim.cmd.tabprev, { silent = true })

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

-- Yanking and pasting clipboard {{{
vnoremap('<C-y>', '"+y')
nnoremap('<C-p>', '"+p')
vnoremap('<C-p>', '"+p')
-- }}}

-- Splits {{{
-- 'Maximize' window
nnoremap('<C-w>m', '<C-w>_ | <C-w>|')
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

-- Paste but keep register
vnoremap('<leader>p', '"_dP')

-- Copy current filepath
nmap('<leader>yfp', ':let @+ = expand("%")<CR>')

-- Clear search highlighting
nnoremap('<C-h>', vim.cmd.noh, { silent = true })

-- Reparse buffers
nnoremap('<leader>rt', ':write | edit | TSBufEnable highlight<CR>', { silent = true })

-- Git
nnoremap('<leader>gg', vim.cmd.Git, { silent = true })
nnoremap('<leader>gq',
  function()
    util.visit_buffers(function(b)
      util.apply_function_for_buffer_with_ft(b, 'fugitive', util.delete_buffer_func(b, {}))
    end)
  end, { silent = true, })
nnoremap('<leader>gP', ':Git push<CR>')
nnoremap('<leader>gsP', ':Git push -u origin HEAD<CR>')
nnoremap('<leader>gp', ':Git pull<CR>')
nnoremap('<leader>gcb', ':Git checkout -b ')
nnoremap('<leader>gc-', ':Git checkout -')
nnoremap('<leader>gh', ':Git log -p -- <C-r>%<CR>')

-- Git flow mappings
-- Feature
nnoremap('<leader>gffs', ':Git flow feature start ')
-- Bugfix
nnoremap('<leader>gfbs', ':Git flow bugfix start ')
-- Support
nnoremap('<leader>gfss', ':Git flow support start ')
-- Hotfix
nnoremap('<leader>gfhs', ':Git flow hotfix start ')


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
nnoremap('<leader>cn', vim.cmd.cnext)
nnoremap('<leader>cp', vim.cmd.cprev)
nnoremap('<leader>co', vim.cmd.copen, { silent = true })
nnoremap('<leader>cc', vim.cmd.cc, { silent = true })
nnoremap('<leader>cC', vim.cmd.cclose, { silent = true })

-- Location list navigation
nnoremap('<leader>ln', vim.cmd.lnext)
nnoremap('<leader>lp', vim.cmd.lprev)
nnoremap('<leader>lo', vim.cmd.lopen, { silent = true })
nnoremap('<leader>lc', vim.cmd.lc, { silent = true })
nnoremap('<leader>lC', vim.cmd.lclose, { silent = true })

-- Fast search and replace
nnoremap('<leader>sr', ":%s///<Left>")

-- Esc to leave terminal mode
tnoremap('<Esc>', '<C-\\><C-n>')

-- Open undotree
nnoremap('<leader>u', vim.cmd.UndotreeToggle)

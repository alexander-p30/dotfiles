local nmap = require('helper.remap').nmap
local nnoremap = require('helper.remap').nnoremap
local vnoremap = require('helper.remap').vnoremap
local tnoremap = require('helper.remap').tnoremap
local util = require('helper.functions')

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
nnoremap('<leader>tt', vim.cmd.Ttoggle, { silent = true, desc = 'Toggle terminal' })
nnoremap('<leader>tc', ':Tclose!<CR>', { desc = 'Close terminal' })

nnoremap('<leader>alt', ':A<CR>', { desc = 'Alternate between implementation and test files' })

nnoremap('<leader>tn', vim.cmd.TestNearest, { desc = 'Run test on current line' })
nnoremap('<leader>tf', vim.cmd.TestFile, { desc = 'Run test on current file' })
nnoremap('<leader>ts', vim.cmd.TestSuite, { desc = 'Run test suite' })
nnoremap('<leader>tl', vim.cmd.TestLast, { desc = 'Run last test' })
nnoremap('<leader>tv', vim.cmd.TestVisit, { desc = 'Visit last run test' })
-- }}}

-- Tabs {{{
nnoremap('<leader>tan', ':tabedit %<CR>', { silent = true, desc = 'Open current buffer in a new tab' })
nnoremap('<leader>taN', vim.cmd.tabnew, { silent = true, desc = 'Create new tab' })
nnoremap('<leader>taO', vim.cmd.tabonly, { silent = true, desc = 'Close all tabs except current' })
nnoremap('<leader>tac', vim.cmd.tabclose, { silent = true, desc = 'Close current tab' })
nnoremap('<leader>tal', vim.cmd.tabnext, { silent = true, desc = 'Go to tab on the left' })
nnoremap('<leader>tah', vim.cmd.tabprev, { silent = true, desc = 'Go to tab on the right' })

nnoremap('<leader>ta1', '1gt', { silent = true, desc = 'Go to tab #1' })
nnoremap('<leader>ta2', '2gt', { silent = true, desc = 'Go to tab #2' })
nnoremap('<leader>ta3', '3gt', { silent = true, desc = 'Go to tab #3' })
nnoremap('<leader>ta4', '4gt', { silent = true, desc = 'Go to tab #4' })
nnoremap('<leader>ta5', '5gt', { silent = true, desc = 'Go to tab #5' })
nnoremap('<leader>ta6', '6gt', { silent = true, desc = 'Go to tab #6' })
nnoremap('<leader>ta7', '7gt', { silent = true, desc = 'Go to tab #7' })
nnoremap('<leader>ta8', '8gt', { silent = true, desc = 'Go to tab #8' })
nnoremap('<leader>ta9', '9gt', { silent = true, desc = 'Go to tab #9' })
-- }}}

-- Yanking and pasting clipboard {{{
vnoremap('<C-y>', '"+y')
nnoremap('<C-p>', '"+p')
vnoremap('<C-p>', '"+p')
-- }}}

-- Splits {{{
-- 'Maximize' window
nnoremap('<C-w>m', '<C-w>_ | <C-w>|')

-- Movement
nnoremap('<C-h>', '<cmd> TmuxNavigateLeft<CR>')
nnoremap('<C-j>', '<cmd> TmuxNavigateDown<CR>')
nnoremap('<C-k>', '<cmd> TmuxNavigateUp<CR>')
nnoremap('<C-l>', '<cmd> TmuxNavigateRight<CR>')
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
nnoremap('<C-b>', ':Neotree toggle=true reveal<CR>', { silent = true, desc = 'Neotree' })
-- }}}

nnoremap('<C-t>', '<C-6>', { silent = true })

-- Copy until end of line
nnoremap('Y', 'y$')

-- Paste but keep register
vnoremap('<leader>p', '"_dP', { desc = 'Paste but keep register' })

-- Copy current filepath
nmap('<leader>yfp', ':let @+ = expand("%")<CR>', { desc = 'Copy current file path to system clipboard' })

-- Clear search highlighting
nnoremap('<leader>noh', vim.cmd.noh, { silent = true, desc = 'Clear search highlight' })

-- Reparse buffers
nnoremap(
  '<leader>rt',
  ':write | edit | TSBufEnable highlight<CR>',
  { silent = true, desc = 'Reload tree-sitter hightlight for current buffer' }
)

-- Git
nnoremap(
  '<leader>gg',
  function()
    local fugitive = nil

    util.visit_buffers(function(buf)
      local buf_ft = vim.api.nvim_buf_get_option(buf, 'filetype')
      if buf_ft == 'fugitive' then fugitive = buf end
    end)

    if fugitive then vim.api.nvim_buf_delete(fugitive, {}) else vim.cmd.Git() end
  end,
  { silent = true, desc = 'Toggle fugitive' }
)
nnoremap('<leader>gr', vim.cmd.Git, { desc = 'Open/refresh fugitive buffer' })
nnoremap('<leader>gmh', '<cmd>diffget //2<CR>', { desc = 'Get diff from file on the left' })
nnoremap('<leader>gml', '<cmd>diffget //3<CR>', { desc = 'Get diff from file on the right' })
nnoremap('<leader>gP', ':Git push<CR>')
nnoremap('<leader>gsP', ':Git push -u origin HEAD<CR>')
nnoremap('<leader>gp', ':Git pull<CR>')
nnoremap('<leader>gcb', ':Git checkout -b ')
nnoremap('<leader>gc-', ':Git checkout -', { desc = 'Checkout to last branch' })
nnoremap('<leader>ghi', ':Git log -p -- <C-r>%<CR>', { desc = 'Open git history for file' })

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
nnoremap('<leader>db', ':%bd <bar> e#', { desc = 'Populate comand with delete all buffers except current' })
nnoremap('<leader>dab', ':%bd', { desc = 'Populate comand with delete all buffers' })

-- Increment number under the cursor
nnoremap('<C-s>', '<C-a>')

-- Sort selection
vnoremap('<leader>so', ':\'<,\'>sort i<CR>', { silent = true, desc = 'Sort selected lines' })

-- Move visual selection
vnoremap('<Up>', ':m \'<-2<CR>gv=gv', { desc = 'Move selected lines up' })
vnoremap('<Down>', ':m \'>+1<CR>gv=gv', { desc = 'Move selected lines down' })

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
nnoremap('<leader>sr', ':%s///<Left>', { desc = 'Populate command to search and replace' })

-- Esc to leave terminal mode
tnoremap('<Esc>', '<C-\\><C-n>')

-- Open undotree
nnoremap('<leader>u', vim.cmd.UndotreeToggle, { desc = 'Open undotree' })

-- Dismiss notifications
nnoremap('<leader>nd', vim.notify.dismiss, { desc = 'Dismiss all notifications' })

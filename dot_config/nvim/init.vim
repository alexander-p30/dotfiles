" vim:foldmethod=marker

" Plugin managing {{{
" Automatically install new plugins
autocmd VimEnter *
  \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \|   PlugInstall --sync | q | so ~/.config/nvim/init.vim
  \| endif

call plug#begin('~/.vim/plugged')
" File-related
Plug 'nvim-neo-tree/neo-tree.nvim'
Plug 'nvim-telescope/telescope.nvim' |
      \ Plug 'nvim-lua/plenary.nvim' |
      \ Plug 'nvim-lua/popup.nvim'   |
      \ Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" Fonts and assets
Plug 'lambdalisue/nerdfont.vim'

" Git
Plug 'airblade/vim-gitgutter'
Plug 'APZelos/blamer.nvim'
Plug 'tpope/vim-fugitive'

" LS, syntax highlighting and programming utils
Plug 'neovim/nvim-lspconfig' |
      \ Plug 'williamboman/nvim-lsp-installer'
Plug 'hrsh7th/cmp-nvim-lsp' |
      \ Plug 'hrsh7th/cmp-buffer' |
      \ Plug 'hrsh7th/nvim-cmp' |
      \ Plug 'saadparwaiz1/cmp_luasnip' |
      \ Plug 'L3MON4D3/LuaSnip'
Plug 'ray-x/lsp_signature.nvim'
Plug 'onsails/lspkind-nvim'
Plug 'vim-test/vim-test'
Plug 'elixir-editors/vim-elixir', { 'for': 'elixir' }
Plug 'rstacruz/vim-closer'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise', { 'for': ['ruby', 'elixir'], 'commit': '9471eeb' }
Plug 'mg979/vim-visual-multi'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'} |
      \ Plug 'nvim-treesitter/playground', { 'on': ['TSPlaygroundToggle', 'TSHighlightCapturesUnderCursor'] } |
      \ Plug 'p00f/nvim-ts-rainbow'
Plug 'neovimhaskell/haskell-vim', { 'for': 'haskell' }
Plug 'mboughaba/i3config.vim', { 'for': 'i3config' }
Plug 'fladson/vim-kitty'
Plug 'RRethy/vim-illuminate'
Plug 'kmonad/kmonad-vim'
Plug 'tversteeg/registers.nvim', { 'branch': 'main' }
Plug 'Olical/conjure', { 'for': 'clojure' }
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'rust-lang/rust.vim'

" Projectionist
Plug 'tpope/vim-projectionist'
Plug 'c-brenn/fuzzy-projectionist.vim'
Plug 'andyl/vim-projectionist-elixir'

" Other
Plug 'kassio/neoterm'
Plug 'antoinemadec/FixCursorHold.nvim'
Plug 'olimorris/persisted.nvim'
Plug 'simeji/winresizer'
Plug 'ustrajunior/ex_maps'

" Themes / Visual
Plug 'navarasu/onedark.nvim'
Plug 'catppuccin/nvim', {'as': 'catppuccin'}
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }
Plug 'tiagovla/tokyodark.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'nvim-lualine/lualine.nvim'
Plug 'NTBBloodbath/doom-one.nvim'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'folke/which-key.nvim' 
Plug 'MunifTanjim/nui.nvim'
call plug#end()
" }}}

let g:neo_tree_remove_legacy_commands = 1

" Folding {{{
set nofoldenable
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
" }}}

" General Sets and Cmds {{{
" Indentation
set tabstop=2 softtabstop=2
set shiftwidth=2
set expandtab
set smartindent

set timeoutlen=500
set updatetime=500
" Dinamically loaded vim configs
set exrc

" Text editing
" Line information
set relativenumber
set number

set nowrap

" Swap and backup
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set hidden

" trigger `autoread` when files changes on disk
set autoread
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif

lua << EOF
-- Add lines to neoterm
function addLinesToTerm()
  local buf_ft = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "filetype")
  if buf_ft == "neoterm" then
    vim.api.nvim_command("set relativenumber")
    vim.api.nvim_command("set number")
  end
end

local term_group = vim.api.nvim_create_augroup("term_group", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", { 
  group = term_group,
  pattern = "term:/*neoterm*",
  callback = addLinesToTerm
})
EOF

set title
set incsearch
set scrolloff=4
set completeopt=menuone,noinsert,noselect
set signcolumn=yes
set colorcolumn=100,120
set cursorline
set termguicolors

" Split behaviour
set noequalalways
set splitbelow
set splitright
" }}}

syntax enable

" Plugin configs {{{
"  ex_maps
lua require("ex_maps").setup { create_mappings = true, mapping = "mtt" }

" nvim-web-devicons
lua require'nvim-web-devicons'.setup { default = true; }

" vim-test
let test#strategy = "neoterm"

" neoterm
let g:neoterm_default_mod = 'botright'
let g:neoterm_size = ''
let g:neoterm_autoscroll = 1
let g:neoterm_automap_keys = ''

" gitgutter {{{
let gitgutter_character = "▋"
let g:gitgutter_sign_added = gitgutter_character
let g:gitgutter_sign_modified = gitgutter_character
let g:gitgutter_sign_removed = gitgutter_character
let g:gitgutter_sign_removed_first_line = gitgutter_character
let g:gitgutter_sign_removed_above_and_below = gitgutter_character
let g:gitgutter_sign_modified_removed = gitgutter_character
" }}}

" git-blamer {{{
let g:blamer_enabled = 1
let g:blamer_show_in_visual_modes = 0
let g:blamer_delay = 500
let g:blamer_prefix = ' 🤡 '
" }}}

" Keybindings {{{
let mapleader = " "

" Add {count}k and {count}j to jumplist
nnoremap <expr> k (v:count > 1 ? "m'" . v:count : '') . 'k'
nnoremap <expr> j (v:count > 1 ? "m'" . v:count : '') . 'j'

" Terminal/test-related bindings {{{
nnoremap <silent> <leader>tt :Ttoggle<CR>
nnoremap <leader>alt :A<CR>

nnoremap <leader>tn :call TestInNeoterm('tn')<CR>
nnoremap <leader>tf :call TestInNeoterm('tf')<CR>
nnoremap <leader>ts :call TestInNeoterm('ts')<CR>
nnoremap <leader>tl :call TestInNeoterm('tl')<CR>
nnoremap <leader>twf :T find test lib \| entr -cr mix test %<CR>
nnoremap <leader>tws :T find test lib \| entr -cr mix test %:<C-r>=line('.')<CR><CR>

nnoremap <leader>tv :TestVisit<CR>
nnoremap <leader>tc :Tclose!<CR>
" }}}

" Tabs {{{
nnoremap <silent> <leader>tan :tabedit %<CR> 
nnoremap <silent> <leader>taN :tabnew<CR> 
nnoremap <silent> <leader>taO :tabonly<CR> 
nnoremap <silent> <leader>tac :tabclose<CR> 
nnoremap <silent> <leader>tal :tabnext<CR> 
nnoremap <silent> <leader>tah :tabprevious<CR> 

nnoremap <silent> <leader>ta1 1gt
nnoremap <silent> <leader>ta2 2gt
nnoremap <silent> <leader>ta3 3gt
nnoremap <silent> <leader>ta4 4gt
nnoremap <silent> <leader>ta5 5gt
nnoremap <silent> <leader>ta6 6gt
nnoremap <silent> <leader>ta7 7gt
nnoremap <silent> <leader>ta8 8gt
nnoremap <silent> <leader>ta9 9gt
" }}}

" Linting {{{
nnoremap <leader>cq :call LintInNeoterm()<CR>
" }}}

" Yanking and pasting clipboard {{{
vnoremap <C-y> "+y
nnoremap <C-p> "+p
vnoremap <C-p> "+p
" }}}

" Writing and Closing {{{
nnoremap <leader>w :w<CR>
nnoremap <leader>qw :wq<CR>
nnoremap <silent> <leader>qq :q<CR>
nnoremap <leader>qall :qall<CR>
nnoremap <leader>qal! :qall!<CR>
nnoremap <silent> <leader>Q :q!<CR>
" }}}

" Neotree {{{
nnoremap <silent> <C-b> :Neotree toggle=true reveal<CR>
" }}}

" Copy until end of line
nnoremap Y y$

" Copy current filepath
nmap <leader>yfp :let @" = expand("%")<CR>

" Clear search highlighting
nnoremap <silent> <C-h> :noh<CR>

" Update configs
lua << EOF
vim.api.nvim_set_keymap('n', '<leader>re', '', {
  noremap = true,
  silent = true,
  callback = function()
    vim.api.nvim_command('SessionSave')
    vim.api.nvim_command('so')
  end
})
EOF

" Reparse buffers
nnoremap <silent> <leader>rt :write \| edit \| TSBufEnable highlight<CR>

" gitgutter hunk navigation
nnoremap <silent> <CR> :GitGutterNextHunk<CR>
nnoremap <silent> <backspace> :GitGutterPrevHunk<CR>

" Git
nnoremap <silent> <leader>gg :Git<CR>
nnoremap <leader>gP :Git push<CR>
nnoremap <leader>gsP :call SetBranchUpstream()<CR>
nnoremap <leader>gp :Git pull<CR>
nnoremap <leader>gcb :Git checkout -b 
nnoremap <leader>gc- :Git checkout -
nnoremap <leader>gbD :Git branch -D 

" Profiling
nnoremap <leader>profi :call ProfileSession()<CR>
nnoremap <leader>profs :call EndSessionProfiling()<CR>

" Delete current file
nnoremap <Leader>df :call DeleteFileAndCloseBuffer()<CR>

" Delete all buffers
nnoremap <Leader>db :%bd <bar> e#
nnoremap <Leader>dab :%bd

" Increment number under the cursor
nnoremap <C-s> <C-a>

" Sort selection
vnoremap <silent> <leader>so :'<,'>sort<CR>

vnoremap <Up> :m '<-2<CR>gv=gv
vnoremap <Down> :m '>+1<CR>gv=gv

" Quickfix list navigation
nnoremap <leader>cn :cnext <CR>
nnoremap <leader>cp :cprev <CR>
nnoremap <silent> <leader>co :copen <CR>
nnoremap <silent> <leader>cc :cc <CR>
nnoremap <silent> <leader>cC :cclose <CR>

" Location list navigation
nnoremap <leader>ln :lnext <CR>
nnoremap <leader>lp :lprev <CR>
nnoremap <silent> <leader>lo :lopen <CR>
nnoremap <silent> <leader>lc :lc <CR>
nnoremap <silent> <leader>lC :lclose <CR>
" }}}

tnoremap <Esc> <C-\><C-n>

" Theming and styling {{{
" source $HOME/.config/nvim/modules/doom_one.lua

lua << EOF
local catppuccin = require("catppuccin")
-- configure it
catppuccin.setup({ transparent_background = true, term_colors = true, integrations = { telescope = true }})
EOF

lua require("luasnip.loaders.from_snipmate").lazy_load()

let g:catppuccin_flavour = "mocha" " latte, frappe, macchiato, mocha
colorscheme catppuccin
" }}}

highlight LineNr guifg=#9ca0a4

" External Files Sourcing {{{
source $HOME/.config/nvim/modules/cmp.lua
source $HOME/.config/nvim/modules/functions.vim
source $HOME/.config/nvim/modules/hexokinase.vim
source $HOME/.config/nvim/modules/indent_blankline.lua
source $HOME/.config/nvim/modules/lsp.lua
source $HOME/.config/nvim/modules/lualine.lua
source $HOME/.config/nvim/modules/neotree.lua
source $HOME/.config/nvim/modules/persisted.lua
source $HOME/.config/nvim/modules/telescope.lua
source $HOME/.config/nvim/modules/treesitter.lua
source $HOME/.config/nvim/modules/which_key.lua
" }}}

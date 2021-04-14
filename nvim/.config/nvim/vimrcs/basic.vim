""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Show relative line number
set nu rnu

" Clipboard
set clipboard+=unnamedplus

" Mouse
set mouse=n

" Encodeing
set encoding=UTF-8

syntax enable

" auto makeview 
autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent loadview 

set foldmethod=manual
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM UI
"""""""""""""""""""""""""""""""""""""""""""""""""""""

" Word wrap
set wrap linebreak

" Indentation
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Don't redraw while executing macros (good performance config)
set lazyredraw

" Show matching brackets when text indicator is over them
set showmatch

" Set Wild menu
set wildmode=longest,full

" Display the line you are in
set cursorline

" 'Natural' splitting
set splitbelow
set splitright
" ----------------------------------------------------------------------------
" coc.nvim
" ----------------------------------------------------------------------------
" if hidden is not set, TextEdit might fail.
set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

autocmd ColorScheme * highlight SignColumn guibg=none

set timeoutlen=1000 ttimeoutlen=0


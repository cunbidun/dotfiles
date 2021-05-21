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
" autocmd BufWinLeave *.* mkview
" autocmd BufWinEnter *.* silent! loadview 

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
set showtabline=2
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

" don't show mode at the comment line (we already have vim airline)
set noshowmode 


set updatetime=300

set timeoutlen=500 

" always show signcolumns
set signcolumn=yes

set shortmess+=c " Avoid showing message extra message when using completion
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM UI
"""""""""""""""""""""""""""""""""""""""""""""""""""""

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

nmap <M-1> :NERDTreeToggle<CR>

autocmd filetype cpp nnoremap <C-M-b> :w <bar> ! tmux send -t 1 './Script/run.sh "%:p:h/"' Enter <CR> <CR>
autocmd filetype cpp nnoremap <C-M-e> :w <bar> ! tmux send -t 1 './Script/config.sh "%:p:h/"' Enter <CR> <CR>
autocmd filetype cpp nnoremap <C-M-t> :w <bar> ! tmux send -t 1 './Script/test_dialog.sh "%:p:h/"' Enter <CR> <CR>
autocmd filetype cpp nnoremap <C-M-a> :w <bar> ! tmux send -t 1 './Script/archive.sh "%:p:h/"' Enter <CR> <CR>
autocmd filetype cpp nnoremap <C-M-d> :w <bar> ! tmux send -t 1 'mv "%:p:h/" ~/.local/share/Trash/files/' Enter <CR> <CR>
autocmd filetype cpp nnoremap <C-M-n> ! tmux send -t 1 './Script/new.sh ./Task' Enter <CR> <CR>
autocmd filetype cpp nnoremap <C-M-l> :%!astyle -n --add-braces -s2 <bar> clang-format -style="{ColumnLimit: 0, AllowShortBlocksOnASingleLine: false}" <CR>
" CP

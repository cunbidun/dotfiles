call plug#begin('~/.nvim/bundle')
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'tpope/vim-surround'
  Plug 'w0rp/ale'
  Plug 'airblade/vim-gitgutter' " git status on gutter
  Plug 'Yggdroot/indentLine' " for indentation

  Plug 'vim-airline/vim-airline' " status bar
  Plug 'tpope/vim-commentary' " quickly comment 
  Plug 'Raimondi/delimitMate' " provides automatic closing of quotes, parenthesis, brackets, etc.
  Plug 'christoomey/vim-tmux-navigator' " moving between vim buffer and tmux panel
  Plug 'lervag/vimtex' " Latex
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'psliwka/vim-smoothie' " smooth scrolling
  Plug 'Asheq/close-buffers.vim'
  Plug 'arcticicestudio/nord-vim' " nord theme
  Plug 'ap/vim-css-color' " display color hex code
call plug#end()

" commentary
autocmd FileType cpp setlocal commentstring=//\ %s

" set theme
colorscheme nord " nord theme
hi Normal ctermbg=NONE guibg=NONE
if (has("termguicolors"))
  set termguicolors
endif

" Latex
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0

let g:airline_section_b=''
let g:airline#extensions#scrollbar#enabled=0

let g:indentLine_color_gui = '#4C566A'
let g:indentLine_char = '▏'

" Coc
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

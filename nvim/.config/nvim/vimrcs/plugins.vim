""""""""""""""""""
" vim-plug begin "
""""""""""""""""""
call plug#begin('~/.nvim/bundle')
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " Linting                                                           "
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  Plug 'w0rp/ale'

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " Languages                                                         "
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'tpope/vim-surround'
  Plug 'preservim/nerdtree'

  " git
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'

  Plug 'tpope/vim-commentary' " quickly comment 
  Plug 'Raimondi/delimitMate' " provides automatic closing of quotes, parenthesis, brackets, etc.

  " vimwiki
  Plug 'vimwiki/vimwiki'

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " Languages
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " Markdown
  Plug 'godlygeek/tabular'
  Plug 'plasticboy/vim-markdown'
  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install'  }

  " Latex
  Plug 'lervag/vimtex'

  " fzf
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  Plug 'vim-airline/vim-airline' " status bar
  Plug 'easymotion/vim-easymotion'
  Plug 'kevinhwang91/rnvimr', {'do': 'make sync'} " ranger in vim
  Plug 'Yggdroot/indentLine' " for indentation
  " Plug 'yuttie/comfortable-motion.vim' " smooth scrolling 
  Plug 'psliwka/vim-smoothie'
  Plug 'Asheq/close-buffers.vim'


  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " Visualization 
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  Plug 'arcticicestudio/nord-vim' " nord theme
  Plug 'altercation/vim-colors-solarized' " solarized theme
  Plug 'ryanoasis/vim-devicons' " icon pack
  Plug 'ap/vim-css-color'
call plug#end()
"""""""""""""""
" vim-plug end"
"""""""""""""""
" scrolling
" let g:comfortable_motion_friction = 200.0
" let g:comfortable_motion_air_drag = 0.0

" set vimwiki default file type to md
let g:vimwiki_list = [{'path': '~/vimwiki/',
                      \ 'syntax': 'markdown', 'ext': '.md'}]

" Disable auto folding for markdown
let g:vim_markdown_folding_disabled = 1

" NEEDTRee
let NERDTreeShowHidden = 1
let NERDTreeMinimalUI = 1

" commentary
autocmd FileType cpp setlocal commentstring=//\ %s

" devicons
let g:webdevicons_enable = 1
let g:webdevicons_enable_nerdtree = 1

" Theme
"""""""""""""""""""
colorscheme nord " nord theme
"""""""""""""""""""
" set background=light
" colorscheme solarized
"""""""""""""""""""

if (has("termguicolors"))
  set termguicolors
endif

" Latex
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0

" indentation
let g:indentLine_color_gui = '#4C566A'
" let g:indentLine_setConceal = 0

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

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

nmap <M-1> :NERDTreeToggle<CR>
let g:NERDTreeWinSize=45

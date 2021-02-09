tnoremap <Esc> <C-\><C-n>

function! TermWrapper(command) 
  exec 'wa'
  exec 'Bdelete! other'
  let g:current_window = win_getid()
  exec 'mkview'
	exec 'vnew'
	exec 'vertical resize 30'
	" exec 'vertical resize 63'
  set nonu
  set rnu!
	exec 'term ' . a:command
  exec '$'
  exec printf('exec win_gotoid(%s)', g:current_window) 
  exec 'loadview'
endfunction

function! FormatWrapper() 
  exec 'mkview' 
  exec '%!astyle -n --add-braces -s2 | clang-format -style="{ColumnLimit: 0, AllowShortBlocksOnASingleLine: false}"'
  exec 'loadview'
endfunction

command! -nargs=0 Runscript call TermWrapper(printf('./Script/run.sh "%s"', expand('%:p:h')))
command! -nargs=0 RunWithTerm call TermWrapper(printf('./Script/run_with_terminal.sh "%s"', expand('%:p:h')))
command! -nargs=0 TaskConfig call TermWrapper(printf('./Script/config.sh "%s"', expand('%:p:h')))
command! -nargs=0 ArchiveTask call TermWrapper(printf('./Script/archive.sh "%s"', expand('%:p:h')))
command! -nargs=0 DeleteTask call TermWrapper(printf('mv "%s" ~/.local/share/Trash/files/', expand('%:p:h')))
command! -nargs=0 NewTask call TermWrapper(printf('./Script/new.sh ./Task'))
command! -nargs=0 FormatCode call FormatWrapper()

" TMUX
" autocmd filetype cpp nnoremap <C-M-b> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/run.sh "%:p:h/"' Enter <CR> <CR>
" autocmd filetype cpp nnoremap <C-M-e> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/config.sh "%:p:h/"' Enter <CR> <CR>
" autocmd filetype cpp nnoremap <C-M-a> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/archive.sh "%:p:h/"' Enter <CR> <CR>
" autocmd filetype cpp nnoremap <C-M-d> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 'mv "%:p:h/" ~/.local/share/Trash/files/' Enter <CR> <CR>
" autocmd filetype cpp nnoremap <C-M-t> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/test_dialog.sh "%:p:h/"' Enter <CR> <CR>
" autocmd filetype cpp nnoremap <C-M-n> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/new.sh ./Task' Enter <CR> <CR>

" VIM
" autocmd filetype cpp nnoremap <C-M-b> :w <bar> :Bdelete! other<CR> <bar> :Runscript<CR>
autocmd filetype cpp nnoremap <C-M-b> :w <bar> :Runscript<CR>
autocmd filetype cpp nnoremap <leader><C-M-b> :w <bar> :RunWithTerm<CR>
autocmd filetype cpp nnoremap <C-M-t> :w <bar> :TaskConfig<CR>
autocmd filetype cpp nnoremap <C-M-a> :w <bar> :ArchiveTask<CR>
autocmd filetype cpp nnoremap <C-M-d> :w <bar> :DeleteTask<CR>
autocmd filetype cpp nnoremap <C-M-n> :w <bar> :NewTask<CR>
autocmd filetype cpp nnoremap <C-M-l> :FormatCode<CR> 


" autocmd filetype cpp nnoremap <C-M-l> :%!astyle -n --add-braces -s2 <bar> clang-format -style="{ColumnLimit: 0, AllowShortBlocksOnASingleLine: false}" <CR> <CR>



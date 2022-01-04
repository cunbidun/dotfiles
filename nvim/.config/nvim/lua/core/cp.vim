tnoremap <Esc> <C-\><C-n>

let g:cpTermSize = '100'

function! TermWrapper(command) 
	exec 'wa'
	" exec 'silent! only'
	" let g:current_window = win_getid()
	" exec 'mkview'
	" exec 'vnew'
	" exec 'vertical resize ' . g:cpTermSize
	" set nonu
	" set nornu
	" exec 'term ' . a:command
	" exec '$'
	" exec printf('exec win_gotoid(%s)', g:current_window) 
	" exec 'loadview'
	exec "TermExec direction=vertical cmd='clear' go_back=0" 
  exec "bdelete!"
	exec printf("TermExec direction=vertical cmd='%s'", a:command) 
endfunction

command! -nargs=0 Runscript call TermWrapper(printf('"$CPCLI_PATH/main.sh" "%s" 0', expand('%:p:h')))
command! -nargs=0 RunWithDebug call TermWrapper(printf('"$CPCLI_PATH/main.sh" "%s" 1', expand('%:p:h')))
command! -nargs=0 RunWithTerm call TermWrapper(printf('"$CPCLI_PATH/main.sh" "%s" 2', expand('%:p:h')))
command! -nargs=0 TaskConfig call TermWrapper(printf('"$CPCLI_PATH/main.sh" "%s" 3', expand('%:p:h')))
command! -nargs=0 ArchiveTask call TermWrapper(printf('"$CPCLI_PATH/main.sh" "%s" 4', expand('%:p:h')))
command! -nargs=0 NewTask call TermWrapper(printf('"$CPCLI_PATH/main.sh"'))
command! -nargs=0 DeleteTask call TermWrapper(printf('mv "%s" ~/.local/share/Trash/files/', expand('%:p:h')))

" VIM
autocmd filetype cpp nnoremap <C-M-b> :w <bar> :Runscript<CR>
autocmd filetype cpp nnoremap <leader><C-M-b> :w <bar> :RunWithTerm<CR>
autocmd filetype cpp nnoremap <C-M-e> :w <bar> :RunWithDebug<CR>
autocmd filetype cpp nnoremap <C-M-t> :w <bar> :TaskConfig<CR>
autocmd filetype cpp nnoremap <C-M-a> :w <bar> :ArchiveTask<CR>
autocmd filetype cpp nnoremap <C-M-d> :w <bar> :DeleteTask<CR>
autocmd filetype cpp nnoremap <C-M-n> :w <bar> :NewTask<CR>


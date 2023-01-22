tnoremap <Esc> <C-\><C-n>

let g:cpTermSize = '100'

function! TermWrapper(command) 
	exec 'wa'
  let l:buf_id = uniq(map(filter(getwininfo(), 'v:val.terminal'), 'v:val.bufnr'))
  if len(l:buf_id) > 0
    exec printf("%sbdelete!", l:buf_id[0]) 
  endif
	exec printf("TermExec direction=vertical cmd='%s'", a:command) 
endfunction

command! -nargs=0 Runscript    call TermWrapper(printf('clear; cpcli_app task --root-dir="%s" --build', expand('%:p:h')))
command! -nargs=0 RunWithDebug call TermWrapper(printf('clear; cpcli_app task --root-dir="%s" --build-with-debug', expand('%:p:h')))
command! -nargs=0 RunWithTerm call  TermWrapper(printf('clear; cpcli_app task --root-dir="%s" --build-with-term', expand('%:p:h')))
command! -nargs=0 TaskConfig call   TermWrapper(printf('clear; cpcli_app task --root-dir="%s" --edit-problem-config', expand('%:p:h')))
command! -nargs=0 ArchiveTask call  TermWrapper(printf('clear; cpcli_app task --root-dir="%s" --archive', expand('%:p:h')))
command! -nargs=0 NewTask call      TermWrapper(printf('clear; cpcli_app project --new-task'))
command! -nargs=0 DeleteTask call   TermWrapper(printf('mv "%s" ~/.local/share/Trash/files/', expand('%:p:h')))

" VIM
nnoremap <C-M-b> :w <bar> :Runscript<CR>
nnoremap <C-M-r> :w <bar> :RunWithTerm<CR>
nnoremap <C-M-e> :w <bar> :RunWithDebug<CR>
nnoremap <C-M-t> :w <bar> :TaskConfig<CR>
nnoremap <C-M-a> :w <bar> :ArchiveTask<CR>
nnoremap <C-M-d> :w <bar> :DeleteTask<CR>
nnoremap <C-M-n> :w <bar> :NewTask<CR>


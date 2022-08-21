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

command! -nargs=0 Runscript call TermWrapper(printf('clear; cpcli_app --root-dir="%s" --project-config=project_config.json --build', expand('%:p:h')))
command! -nargs=0 RunWithDebug call TermWrapper(printf('clear; cpcli_app --root-dir="%s" --project-config=project_config.json --build-with-debug', expand('%:p:h')))
command! -nargs=0 RunWithTerm call TermWrapper(printf('clear; cpcli_app --root-dir="%s" --project-config=project_config.json --build-with-term', expand('%:p:h')))
command! -nargs=0 TaskConfig call TermWrapper(printf('clear; cpcli_app --root-dir="%s" --project-config=project_config.json --edit-config', expand('%:p:h')))
command! -nargs=0 ArchiveTask call TermWrapper(printf('clear; cpcli_app --root-dir="%s" --project-config=project_config.json --archive', expand('%:p:h')))
command! -nargs=0 NewTask call TermWrapper(printf('clear; cpcli_app --new --project-config=project_config.json'))
command! -nargs=0 DeleteTask call TermWrapper(printf('mv "%s" ~/.local/share/Trash/files/', expand('%:p:h')))

" VIM
autocmd filetype cpp nnoremap <C-M-b> :w <bar> :Runscript<CR>
autocmd filetype cpp nnoremap <C-M-r> :w <bar> :RunWithTerm<CR>
autocmd filetype cpp nnoremap <C-M-e> :w <bar> :RunWithDebug<CR>
autocmd filetype cpp nnoremap <C-M-t> :w <bar> :TaskConfig<CR>
autocmd filetype cpp nnoremap <C-M-a> :w <bar> :ArchiveTask<CR>
autocmd filetype cpp nnoremap <C-M-d> :w <bar> :DeleteTask<CR>
autocmd filetype cpp nnoremap <C-M-n> :w <bar> :NewTask<CR>


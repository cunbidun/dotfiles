" key binding for competitve programming scripts

" run scripts
autocmd filetype cpp nnoremap <C-M-b> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/run.sh "%:p:h/"' Enter <CR> <CR>
" config dialog
autocmd filetype cpp nnoremap <C-M-e> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/config.sh "%:p:h/"' Enter <CR> <CR>
" test_dialog
autocmd filetype cpp nnoremap <C-M-t> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/test_dialog.sh "%:p:h/"' Enter <CR> <CR>
" archive
autocmd filetype cpp nnoremap <C-M-a> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/archive.sh "%:p:h/"' Enter <CR> <CR>
" delete
autocmd filetype cpp nnoremap <C-M-d> :w <bar> ! tmux send-keys -t 1 C-c && tmux send -t 1 'mv "%:p:h/" ~/.local/share/Trash/files/' Enter <CR> <CR>
" new
autocmd filetype cpp nnoremap <C-M-n> ! tmux send-keys -t 1 C-c && tmux send -t 1 './Script/new.sh ./Task' Enter <CR> <CR>
" reformat code
autocmd filetype cpp nnoremap <C-M-l> :%!astyle -n --add-braces -s2 <bar> clang-format -style="{ColumnLimit: 0, AllowShortBlocksOnASingleLine: false}" <CR> <CR>

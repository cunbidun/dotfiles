" set theme
colorscheme nord 

if (has("termguicolors"))
  set termguicolors
endif

" no signcolumn and background
hi Normal ctermbg=NONE guibg=NONE
hi SignColumn guibg=NONE

hi Nord0 guibg=#2E3440
hi Nord9 guifg=#81A1C1 guibg=NONE

hi Error guifg=#BF616A guibg=NONE

hi QuickScopePrimary guifg=#2E3440 guibg=#88C0D0 gui=bold ctermfg=155 cterm=underline
hi QuickScopeSecondary guifg=#2E3440 guibg=#EBCB8B gui=bold ctermfg=81 cterm=underline
" buffer bar
hi BufferCurrent guifg=#88c0d0 guibg=NONE
hi BufferCurrentIndex guifg=#88c0d0 guibg=NONE
hi BufferCurrentSign guifg=#88c0d0 guibg=NONE
hi BufferCurrentIcon guifg=#A3BE8C guibg=NONE

hi BufferVisible guifg=#4C566A guibg=NONE
hi BufferVisibleIndex guifg=#4C566A guibg=NONE
hi BufferVisibleIcon guifg=#4C566A guibg=NONE
hi BufferVisibleSign guifg=#4C566A guibg=NONE

hi BufferInactive guifg=#4C566A guibg=NONE
hi BufferInactiveIndex guifg=#4C566A guibg=NONE
hi BufferInactiveIcon guifg=#4C566A guibg=NONE
hi BufferInactiveSign guifg=#4C566A guibg=NONE

hi BufferCurrentMod guifg=#EBCB8B guibg=NONE
hi BufferInactiveMod guifg=#EBCB8B guibg=NONE
hi BufferVisibleMod guifg=#EBCB8B guibg=NONE

hi BufferOffset guifg=NONE guibg=NONE
hi BufferTabpages guifg=NONE guibg=NONE

hi TabLine guifg=#4C566A guibg=#3B4252 ctermfg=254 ctermbg=238 gui=NONE cterm=NONE
hi TabLineFill guifg=#4C566A guibg=#3B4252 ctermfg=254 ctermbg=NONE gui=NONE cterm=NONE
hi TabLineSel guifg=#88c0d0 guibg=NONE ctermfg=110 ctermbg=240 gui=NONE cterm=NONE

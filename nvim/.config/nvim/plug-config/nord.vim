" set theme
colorscheme nord " nord theme
hi Normal ctermbg=NONE guibg=NONE
if (has("termguicolors"))
  set termguicolors
endif

" work around until nord theme support LSP coloring highlighting group
hi LspDiagnosticsVirtualTextWarning guifg=#EBCB8B gui=underline
hi LspDiagnosticsSignWarning guifg=#EBCB8B
hi LspDiagnosticsUnderlineWarning guifg=#EBCB8B

hi LspDiagnosticsVirtualTextError guifg=#BF616A gui=underline
hi LspDiagnosticsSignError guifg=#BF616A
hi LspDiagnosticsUnderlineError guifg=#BF616A

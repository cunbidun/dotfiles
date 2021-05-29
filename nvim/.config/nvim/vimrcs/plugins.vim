call plug#begin('~/.nvim/bundle')
  Plug 'tpope/vim-surround'
  Plug 'airblade/vim-gitgutter' " git status on gutter
  Plug 'Yggdroot/indentLine' " for indentation

  Plug 'glepnir/galaxyline.nvim'

  Plug 'tpope/vim-commentary' " quickly comment 
  Plug 'Raimondi/delimitMate' " provides automatic closing of quotes, parenthesis, brackets, etc.
  Plug 'christoomey/vim-tmux-navigator' " moving between vim buffer and tmux panel

  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'psliwka/vim-smoothie' " smooth scrolling

  Plug 'lervag/vimtex' " Latex

  Plug 'arcticicestudio/nord-vim' " nord theme
  " Plug 'shaunsingh/nord.nvim'

  Plug 'ap/vim-css-color' " display color hex code

  Plug 'neovim/nvim-lspconfig'
  Plug 'kabouzeid/nvim-lspinstall' " for installing lsp

  " auto completion
  Plug 'hrsh7th/nvim-compe'
  Plug 'hrsh7th/vim-vsnip'

  Plug 'justinmk/vim-sneak'
  
  " navigation tree
  Plug 'kyazdani42/nvim-web-devicons' " for file icons
  Plug 'kyazdani42/nvim-tree.lua'

  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
  Plug 'romgrk/barbar.nvim'
call plug#end()

" commentary
autocmd FileType cpp setlocal commentstring=//\ %s

" Latex
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0

let g:indentLine_color_gui = '#4C566A'
let g:indentLine_char = '▏'

" let g:nord_disable_background=1

" if (has("termguicolors"))
"   set termguicolors
" endif

" hi Normal ctermbg=NONE guibg=NONE
" hi SignColumn guibg=NONE
" colorscheme nord

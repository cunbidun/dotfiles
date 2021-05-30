call plug#begin('~/.nvim/bundle')
  " git
  Plug 'f-person/git-blame.nvim'
  Plug 'airblade/vim-gitgutter' " git status on gutter

  Plug 'tpope/vim-surround'
  Plug 'Yggdroot/indentLine' " for indentation

  " status bar/ tabline
  Plug 'glepnir/galaxyline.nvim' " status bar
  Plug 'romgrk/barbar.nvim' " tabline

  Plug 'tpope/vim-commentary' " quickly comment 
  Plug 'Raimondi/delimitMate' " provides automatic closing of quotes, parenthesis, brackets, etc.
  Plug 'christoomey/vim-tmux-navigator' " moving between vim buffer and tmux panel

  " fzf
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  Plug 'lervag/vimtex' " latex

  " nord theme
  Plug 'arcticicestudio/nord-vim' " nord theme

  Plug 'norcalli/nvim-colorizer.lua' " display color hex code

  Plug 'neovim/nvim-lspconfig'
  Plug 'kabouzeid/nvim-lspinstall' " for installing lsp

  " auto completion
  Plug 'hrsh7th/nvim-compe'
  Plug 'hrsh7th/vim-vsnip'

  " navigation
  Plug 'justinmk/vim-sneak'
  Plug 'psliwka/vim-smoothie' " smooth scrolling
  Plug 'andymass/vim-matchup' " extend neovim % operator
  
  " navigation tree
  Plug 'kyazdani42/nvim-web-devicons' " for file icons
  Plug 'kyazdani42/nvim-tree.lua'

  Plug 'kevinhwang91/rnvimr'

  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
call plug#end()

" commentary
autocmd FileType cpp setlocal commentstring=//\ %s

" Latex
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0

let g:indentLine_color_gui = '#4C566A'
let g:indentLine_char = '▏'

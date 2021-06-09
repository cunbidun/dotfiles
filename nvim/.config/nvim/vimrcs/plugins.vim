call plug#begin('~/.nvim/bundle')
  " git
  Plug 'f-person/git-blame.nvim'
  Plug 'airblade/vim-gitgutter' " git status on gutter

  Plug 'Yggdroot/indentLine' " for indentation

  " status bar/ tabline
  Plug 'glepnir/galaxyline.nvim' " status bar
  Plug 'romgrk/barbar.nvim' " tabline

  " fzf
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  Plug 'lervag/vimtex' " latex

  " nord theme
  Plug 'arcticicestudio/nord-vim' " nord theme
  Plug 'norcalli/nvim-colorizer.lua' " display color hex code

  " lsp
  Plug 'neovim/nvim-lspconfig'
  Plug 'kabouzeid/nvim-lspinstall' " for installing lsp
  Plug 'ahmedkhalf/lsp-rooter.nvim' " auto find and set porject root

  " auto completion
  Plug 'hrsh7th/nvim-compe'
  Plug 'hrsh7th/vim-vsnip'

  " navigation
  Plug 'unblevable/quick-scope'  
  Plug 'phaazon/hop.nvim'
  Plug 'psliwka/vim-smoothie' " smooth scrolling
  Plug 'andymass/vim-matchup' " extend neovim % operator

  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary' " quickly comment 
  Plug 'Raimondi/delimitMate' " provides automatic closing of quotes, parenthesis, brackets, etc.
  
  " explorer
  Plug 'kyazdani42/nvim-web-devicons' " for file icons
  Plug 'kevinhwang91/rnvimr'

  " treesitter
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
  Plug 'christoomey/vim-tmux-navigator' " moving between vim buffer and tmux panel
call plug#end()

" commentary
autocmd FileType cpp setlocal commentstring=//\ %s

" Latex
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0

let g:indentLine_color_gui = '#4C566A'
let g:indentLine_char = '▏'

call plug#begin('~/.nvim/bundle')
  Plug 'nvim-lua/plenary.nvim'

  " git
  Plug 'lewis6991/gitsigns.nvim'
  Plug 'f-person/git-blame.nvim'

  Plug 'lukas-reineke/indent-blankline.nvim' " for indentation

  " status bar/ tabline
  Plug 'glepnir/galaxyline.nvim' " status bar
  Plug 'romgrk/barbar.nvim' " tabline

  " fzf
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  " nord theme
  Plug 'arcticicestudio/nord-vim' " nord theme
  Plug 'norcalli/nvim-colorizer.lua' " display color hex code

  " lsp
  Plug 'neovim/nvim-lspconfig'
  Plug 'kabouzeid/nvim-lspinstall' " for installing lsp
  Plug 'ahmedkhalf/project.nvim'
  Plug 'ray-x/lsp_signature.nvim'

  " vnim snip
  Plug 'hrsh7th/vim-vsnip'

  " auto completion
  Plug 'hrsh7th/nvim-cmp'
  Plug 'hrsh7th/cmp-nvim-lsp' " cmp lsp
  Plug 'hrsh7th/cmp-nvim-lua' " cmp lua vim api
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-calc'
  Plug 'hrsh7th/cmp-vsnip'
  Plug 'hrsh7th/cmp-emoji'
  Plug 'tzachar/cmp-tabnine', { 'do': './install.sh' }

  " navigation
  Plug 'unblevable/quick-scope'  
  Plug 'karb94/neoscroll.nvim' " smooth scrolling

  Plug 'tpope/vim-surround'
  Plug 'terrortylor/nvim-comment' " quickly comment 
  Plug 'windwp/nvim-autopairs' " provides automatic closing of quotes, parenthesis, brackets, etc.

  " explorer
  Plug 'kyazdani42/nvim-web-devicons' " for file icons
  Plug 'kevinhwang91/rnvimr' " ranger
  Plug 'kyazdani42/nvim-tree.lua' " file explorer

  " treesitter
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
  Plug 'nvim-treesitter/nvim-treesitter-refactor'

  Plug 'christoomey/vim-tmux-navigator' " moving between vim buffer and tmux panel

  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
  Plug 'lervag/vimtex' " latex
  
  " term
  Plug 'akinsho/nvim-toggleterm.lua'

call plug#end()

" Latex
let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_mode=0

" plugin config
source $HOME/.config/nvim/plug-config/nord.vim
source $HOME/.config/nvim/plug-config/fzf.vim
source $HOME/.config/nvim/plug-config/cmp.lua
source $HOME/.config/nvim/plug-config/barbar.vim
source $HOME/.config/nvim/plug-config/markdown-preview.vim
luafile $HOME/.config/nvim/plug-config/nvim-treesitter.lua
luafile $HOME/.config/nvim/plug-config/galaxyline.lua
luafile $HOME/.config/nvim/plug-config/colorizer.lua
luafile $HOME/.config/nvim/plug-config/gitblame.nvim.lua
luafile $HOME/.config/nvim/plug-config/rnvimr.lua
luafile $HOME/.config/nvim/plug-config/project.nvim.lua
luafile $HOME/.config/nvim/plug-config/quickscope.lua
luafile $HOME/.config/nvim/plug-config/nvim-toggleterm.lua
luafile $HOME/.config/nvim/plug-config/neoscroll.nvim.lua
luafile $HOME/.config/nvim/plug-config/nvim-tree.lua
luafile $HOME/.config/nvim/plug-config/nvim-comment.lua
luafile $HOME/.config/nvim/plug-config/indent-blankline.nvim.lua
luafile $HOME/.config/nvim/plug-config/nvim-autopairs.lua
luafile $HOME/.config/nvim/plug-config/gitsigns.nvim.lua

" lspconfig
source $HOME/.config/nvim/lsp-config/lsp-config.vim
luafile $HOME/.config/nvim/lsp-config/bash.lua
luafile $HOME/.config/nvim/lsp-config/cpp.lua
luafile $HOME/.config/nvim/lsp-config/efm.lua
luafile $HOME/.config/nvim/lsp-config/lua.lua
luafile $HOME/.config/nvim/lsp-config/json.lua
luafile $HOME/.config/nvim/lsp-config/vim.lua
luafile $HOME/.config/nvim/lsp-config/latex.lua
luafile $HOME/.config/nvim/lsp-config/lsp_signature.lua
luafile $HOME/.config/nvim/lsp-config/python.lua


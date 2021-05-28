source $HOME/.config/nvim/vimrcs/basic.vim
source $HOME/.config/nvim/vimrcs/plugins.vim
source $HOME/.config/nvim/vimrcs/filetype.vim

" plugin config
source $HOME/.config/nvim/plug-config/nord.vim
source $HOME/.config/nvim/plug-config/airline.vim
source $HOME/.config/nvim/plug-config/clang-format.vim
source $HOME/.config/nvim/plug-config/fzf.vim
source $HOME/.config/nvim/plug-config/compe.vim
source $HOME/.config/nvim/plug-config/nvimtree.vim
luafile $HOME/.config/nvim/plug-config/nvim-treesitter.lua
source $HOME/.config/nvim/plug-config/vim-sneak.vim
source $HOME/.config/nvim/plug-config/barbar.vim

" lspconfig
source $HOME/.config/nvim/lsp-config/lsp-config.vim
luafile $HOME/.config/nvim/lsp-config/bash.lua
luafile $HOME/.config/nvim/lsp-config/cpp.lua
luafile $HOME/.config/nvim/lsp-config/efm.lua
luafile $HOME/.config/nvim/lsp-config/lua.lua
luafile $HOME/.config/nvim/lsp-config/json.lua
luafile $HOME/.config/nvim/lsp-config/vim.lua

" competitive programming config
source $HOME/.config/nvim/vimrcs/cp.vim

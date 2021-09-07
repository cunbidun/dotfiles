source $HOME/.config/nvim/vimrcs/basic.vim
source $HOME/.config/nvim/vimrcs/plugins.vim
source $HOME/.config/nvim/vimrcs/filetype.vim

" plugin config
source $HOME/.config/nvim/plug-config/nord.vim
source $HOME/.config/nvim/plug-config/fzf.vim
source $HOME/.config/nvim/plug-config/compe.vim
source $HOME/.config/nvim/plug-config/barbar.vim
source $HOME/.config/nvim/plug-config/markdown-preview.vim
luafile $HOME/.config/nvim/plug-config/nvim-treesitter.lua
luafile $HOME/.config/nvim/plug-config/galaxyline.lua
luafile $HOME/.config/nvim/plug-config/colorizer.lua
luafile $HOME/.config/nvim/plug-config/gitblame.lua
luafile $HOME/.config/nvim/plug-config/rnvimr.lua
luafile $HOME/.config/nvim/plug-config/lsp-rooter.lua
luafile $HOME/.config/nvim/plug-config/quickscope.lua
luafile $HOME/.config/nvim/plug-config/nvim-toggleterm.lua


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

" competitive programming config
source $HOME/.config/nvim/vimrcs/cp.vim

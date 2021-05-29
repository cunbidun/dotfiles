DATA_PATH = vim.fn.stdpath('data')
require'lspconfig'.vimls.setup {
  cmd = {DATA_PATH .. "/lspinstall/vim/node_modules/.bin/vim-language-server", "--stdio"},
}

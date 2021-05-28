DATA_PATH = vim.fn.stdpath('data')
require'lspconfig'.bashls.setup {
  cmd = {DATA_PATH .. "/lspinstall/bash/node_modules/.bin/bash-language-server", "start"},
  filetypes = { "sh", "zsh" }
}

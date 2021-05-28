lua <<EOF
require'lspconfig'.bashls.setup {
  cmd = {"/home/cunbidun/.local/share/nvim/lspinstall/bash/node_modules/.bin/bash-language-server", "start"},
  filetypes = { "sh", "zsh" }
}
EOF

DATA_PATH = vim.fn.stdpath('data')
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

require'lspconfig'.vimls.setup {
  capabilities = capabilities,
  cmd = {DATA_PATH .. '/lspinstall/vim/node_modules/.bin/vim-language-server', '--stdio'}
}

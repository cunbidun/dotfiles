DATA_PATH = vim.fn.stdpath('data')
require'lspconfig'.pyright.setup {
  cmd = {DATA_PATH .. '/lspinstall/python/node_modules/.bin/pyright-langserver', '--stdio'},
  on_attach = function(client)
    client.resolved_capabilities.document_formatting = true
  end
}

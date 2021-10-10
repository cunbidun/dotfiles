DATA_PATH = vim.fn.stdpath('data')
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

require'lspconfig'.texlab.setup {
  capabilities = capabilities,
  cmd = {DATA_PATH .. '/lspinstall/latex/texlab'},
  on_attach = function(client)
    client.resolved_capabilities.document_formatting = true
  end
}

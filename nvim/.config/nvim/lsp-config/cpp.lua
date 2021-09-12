DATA_PATH = vim.fn.stdpath('data')
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

require'lspconfig'.clangd.setup {
  capabilities = capabilities,
  cmd = {
    DATA_PATH .. '/lspinstall/cpp/clangd/bin/clangd', '--background-index', '--header-insertion=never',
    '--cross-file-rename', '--clang-tidy', '--clang-tidy-checks=-*,llvm-*,clang-analyzer-*'
  },
  on_attach = function(client)
    client.resolved_capabilities.document_formatting = true
  end,
  handlers = {
    ['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = true
    })
  }
}

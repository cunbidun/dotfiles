lua <<EOF
require'lspconfig'.clangd.setup {
  handlers = {
    ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      update_in_insert = true,
    })
  }
}
EOF
DATA_PATH = vim.fn.stdpath('data')
require'lspconfig'.clangd.setup {
  cmd = {DATA_PATH .. "/lspinstall/cpp/clangd/bin/clangd"},
  handlers = {
    ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = true
    })
  }
}
DATA_PATH = vim.fn.stdpath('data')
require'lspconfig'.jsonls.setup {
  cmd = {
    'node', DATA_PATH .. '/lspinstall/json/vscode-json/json-language-features/server/dist/node/jsonServerMain.js',
    '--stdio'
  },
  on_attach = function(client)
    client.resolved_capabilities.document_formatting = true
  end,
  commands = {
    Format = {
      function()
        vim.lsp.buf.range_formatting({}, {0, 0}, {vim.fn.line('$'), 0})
      end
    }
  }
}

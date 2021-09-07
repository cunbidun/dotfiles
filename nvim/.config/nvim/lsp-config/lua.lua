DATA_PATH = vim.fn.stdpath('data')

require'lspconfig'.sumneko_lua.setup {
  cmd = {DATA_PATH .. '/lspinstall/lua/sumneko-lua-language-server', '-E', DATA_PATH .. '/lspinstall/lua/main.lua'},
  on_attach = function(client)
    client.resolved_capabilities.document_formatting = false
  end,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Setup your lua path
        path = vim.split(package.path, ';')
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'}
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = {[vim.fn.expand('$VIMRUNTIME/lua')] = true, [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true},
        maxPreload = 10000
      }
    }
  }
}

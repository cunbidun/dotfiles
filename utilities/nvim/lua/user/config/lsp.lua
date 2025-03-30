-- lus LSP configurations
vim.lsp.config.luals = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc" },
  settings = {
    Lua = {
      workspace = {
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
}

-- C/C++ Language Server configuration
vim.lsp.config.clangd = {
  cmd = { "clangd", "--background-index" },
  root_markers = { "compile_commands.json", "compile_flags.txt" },
  filetypes = { "c", "cpp" },
}

vim.lsp.config.nixd = {
  cmd = { "nixd" },
  root_markers = { "flake.nix", "default.nix", "shell.nix" },
  filetypes = { "nix" },
  settings = {
    nix = {
      format = {
        enable = true,
      },
    },
  },
}

vim.diagnostic.config({ virtual_lines = true })
vim.lsp.enable({ "luals", "nil_ls", "nixd", "pyright", "ruff", "bashls", "clangd" })

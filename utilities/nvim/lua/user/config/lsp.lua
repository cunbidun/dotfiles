-- Lua LSP configurations
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

vim.lsp.config.ts_ls = {
  cmd = { "typescript-language-server", "--stdio" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
}

vim.lsp.config.jsonls = {
  cmd = { "vscode-json-language-server", "--stdio" },
  root_markers = { "package.json", ".git" },
  filetypes = { "json", "jsonc" },
}

vim.lsp.config.yamlls = {
  cmd = { "yaml-language-server", "--stdio" },
  root_markers = { ".git" },
  filetypes = { "yaml", "yml" },
}

vim.lsp.config.html = {
  cmd = { "vscode-html-language-server", "--stdio" },
  root_markers = { "package.json", ".git" },
  filetypes = { "html" },
}

vim.lsp.config.cssls = {
  cmd = { "vscode-css-language-server", "--stdio" },
  root_markers = { "package.json", ".git" },
  filetypes = { "css", "scss", "less" },
}

vim.diagnostic.config({ virtual_lines = true })
vim.lsp.enable({
  "luals",
  "nil_ls",
  "nixd",
  "pyright",
  "ruff",
  "bashls",
  "clangd",
  "ts_ls",
  "jsonls",
  "yamlls",
  "html",
  "cssls",
})

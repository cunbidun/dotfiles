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

vim.lsp.config.nil_ls = {
  cmd = { "nil" },
  root_markers = { "flake.nix", "default.nix", "shell.nix" },
  filetypes = { "nix" },
}

vim.lsp.config.pyright = {
  cmd = { "pyright-langserver", "--stdio" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  filetypes = { "python" },
}

vim.lsp.config.ruff = {
  cmd = { "ruff", "server" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  filetypes = { "python" },
}

vim.lsp.config.bashls = {
  cmd = { "bash-language-server", "start" },
  root_markers = { ".git" },
  filetypes = { "bash", "sh" },
}

vim.lsp.config.copilot = {
  cmd = { "copilot-language-server", "--stdio" },
  root_markers = { ".git" },
  filetypes = {
    "bash",
    "c",
    "cpp",
    "lua",
    "nix",
    "python",
    "sh",
  },
}

vim.diagnostic.config({ virtual_lines = true })
vim.lsp.enable({ "luals", "nil_ls", "nixd", "pyright", "ruff", "bashls", "clangd", "copilot" })

vim.schedule(function()
  vim.api.nvim_exec_autocmds("FileType", {})
end)

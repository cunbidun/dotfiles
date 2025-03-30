vim.o.completeopt = "menu,noinsert,popup,fuzzy"

-- lus LSP configurations
vim.lsp.config["luals"] = {
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

-- Enable LSP completion on attach
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end
    if not client.server_capabilities or not client.server_capabilities.completionProvider then
      return
    end
    client.server_capabilities.completionProvider.triggerCharacters = vim.split("qwertyuiopasdfghjklzxcvbnm. ", "")
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
      })
    end

    vim.keymap.set("i", "<cr>", function()
      if vim.fn.pumvisible() == 1 then
        return "<C-y>"
      else
        return "<cr>"
      end
    end, { expr = true })
  end,
})

-- general settings for language servers
vim.diagnostic.config({ virtual_lines = true })
vim.lsp.enable({ "luals", "nil_ls", "nixd", "pyright", "ruff", "bashls", "clangd" })

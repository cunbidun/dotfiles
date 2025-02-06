return {
  "vim-plugins/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "vim-plugins/cmp-nvim-lsp",
    { "vim-plugins/neodev.nvim", opts = {} },
  },
  config = function()
    local __lspServers = {
      { name = "ruff" },
      { name = "pyright" },
      { name = "nixd" },
      { name = "lua_ls" },
      { name = "clangd" },
      { name = "bashls" },
    }

    local M = {}

    -- Adding lspOnAttach function to nixvim module lua table so other plugins can hook into it.
    M.lspOnAttach = function(client, bufnr) end
    local __lspCapabilities = function()
      capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
      return capabilities
    end

    local __setup = {
      on_attach = M.lspOnAttach,
      capabilities = __lspCapabilities(),
    }

    for i, server in ipairs(__lspServers) do
      if type(server) == "string" then
        require("lspconfig")[server].setup(__setup)
      else
        local options = server.extraOptions

        if options == nil then
          options = __setup
        else
          options = vim.tbl_extend("keep", options, __setup)
        end

        require("lspconfig")[server.name].setup(options)
      end
    end
  end,
}

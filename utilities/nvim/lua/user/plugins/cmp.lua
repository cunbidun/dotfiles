return {
  "vim-plugins/nvim-cmp",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "vim-plugins/lspkind.nvim",
  },
  config = function()
    local cmp = require("cmp")
    cmp.setup({
      formatting = {
        format = require("lspkind").cmp_format({
          menu = { buffer = "[buffer]", luasnip = "[snip]", nvim_lsp = "[LSP]", nvim_lua = "[api]", path = "[path]" },
        }),
      },
      mapping = {
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<S-Tab>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "s" }),
        ["<Tab>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "s" }),
      },
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      sources = {
        { name = "path" },
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer", option = { get_bufnrs = vim.api.nvim_list_bufs } },
      },
    })
  end,
  enabled = not vim.g.vscode
}

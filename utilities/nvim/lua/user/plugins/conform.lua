return {
  "vim-plugins/conform.nvim",
  event = "BufEnter",
  config = function()
    require("conform").setup({
      format_on_save = { lspFallback = true, timeoutMs = 500 },
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
        lua = { "stylua" },
        nix = { "alejandra" },
        py = { "black" },
        sh = { "shfmt" },
      },
    })
  end,
}

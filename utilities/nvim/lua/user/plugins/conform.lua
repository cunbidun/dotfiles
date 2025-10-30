local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    c = { "clang-format" },
    cpp = { "clang-format" },
    h = { "clang-format" },
    hpp = { "clang-format" },
  },
  formatters = {
    ["clang-format"] = {
      command = "clang-format",
      args = { "--style=file" },
    },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})
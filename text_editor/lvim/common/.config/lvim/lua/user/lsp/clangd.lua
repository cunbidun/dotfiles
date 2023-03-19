-- clangd {{{
local capabilities = require("lvim.lsp").common_capabilities()
capabilities.offsetEncoding = { "utf-16" }
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "clangd" })
local clangd_flags = {
	capabilities = capabilities,
	"--fallback-style=google",
	"--background-index",
	"-j=12",
	"--all-scopes-completion",
	"--pch-storage=disk",
	"--clang-tidy",
	"--log=error",
	"--completion-style=detailed",
	"--header-insertion=iwyu",
	"--header-insertion-decorators",
	"--enable-config",
	"--offset-encoding=utf-16",
	"--ranking-model=heuristics",
	"--folding-ranges",
}
local clangd_bin = "clangd"
local opts = {
	cmd = { clangd_bin, unpack(clangd_flags) },
}
require("lvim.lsp.manager").setup("clangd", opts)
-- }}}

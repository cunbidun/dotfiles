local M = {
	setup = function() end,
}

local present1, null_ls = pcall(require, "null-ls")

local present2, lspconfig = pcall(require, "lspconfig")
if not present1 or not present2 then
	return M
end

M.setup = function()
	local sources = {
		null_ls.builtins.formatting.prettier.with({ filetypes = { "html", "yaml", "markdown" } }),
		null_ls.builtins.diagnostics.write_good.with({ filetypes = { "markdown", "text", "latex" } }),
		null_ls.builtins.diagnostics.codespell.with({ filetypes = { "markdown", "text", "latex" } }),

		------------------------------------latex-----------------------------------------
		-- null_ls.builtins.diagnostics.chktex,

		------------------------------------lua-----------------------------------------
		null_ls.builtins.formatting.stylua.with({ filetypes = { "lua" } }),

		------------------------------------python-----------------------------------------
		null_ls.builtins.formatting.isort.with({ filetypes = { "python" } }),
		null_ls.builtins.formatting.black.with({ filetypes = { "python" } }),
		null_ls.builtins.diagnostics.flake8.with({ filetypes = { "python" } }),

		------------------------------------shell-----------------------------------------
		null_ls.builtins.formatting.shfmt.with({ extra_args = { "-i", "2", "-ci" } }),
		null_ls.builtins.diagnostics.shellcheck.with({ diagnostics_format = "[#{c}] #{m} (#{s})" }),

		------------------------------------git-----------------------------------------
		null_ls.builtins.code_actions.gitsigns,
	}
	null_ls.config({
		sources = sources,
		diagnostics_format = "#{m}",
		debounce = 250,
		default_timeout = 5000,
	})

	lspconfig["null-ls"].setup({
		on_attach = function(client, bufnr)
			-- if client.resolved_capabilities.document_formatting then
			--   vim.cmd('autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()')
			-- end
		end,
	})
end

return M

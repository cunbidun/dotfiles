return {
	{
		"stevearc/conform.nvim",
		optional = true,
		opts = function(_, opts)
			opts.formatters = opts.formatters or {}
			opts.formatters.sqlfluff = vim.tbl_deep_extend("force", opts.formatters.sqlfluff or {}, {
				cwd = false,
				require_cwd = false,
			})
			return opts
		end,
	},
}

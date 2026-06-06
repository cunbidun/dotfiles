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
	-- Disable LSP keymaps that conflict with competitive programming bindings.
	-- <leader>ca (CodeAction) and <leader>cr (Rename) clash with CP Archive/Run.
	-- The user's own bindings are <leader>rn (rename) and <leader>ca (→ CP Archive via cp.lua).
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				["*"] = {
					keys = {
						{ "<leader>ca", false },
						{ "<leader>cr", false },
					},
				},
			},
		},
	},
	-- Tab accepts the current completion (merged on top of the default preset).
	{
		"saghen/blink.cmp",
		opts = {
			keymap = {
				["<Tab>"] = { "select_and_accept", "fallback" },
			},
		},
	},
	-- Explorer: make 'o' navigate into directories (same as Enter/l) instead of opening externally.
	{
		"folke/snacks.nvim",
		opts = {
			picker = {
				sources = {
					explorer = {
						win = {
							list = {
								keys = {
									["o"] = "confirm",
								},
							},
						},
					},
				},
			},
		},
	},
}

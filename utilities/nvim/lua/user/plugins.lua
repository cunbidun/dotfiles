return {
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
	-- Hide __pycache__ and compiled Python files from the explorer.
	-- git_status_hl colors filenames by git status (VS Code style).
	{
		"folke/snacks.nvim",
		opts = {
			picker = {
				sources = {
					explorer = {
						exclude = { "__pycache__", "*.pyc" },
					},
				},
				formatters = {
					file = {
						git_status_hl = true,
					},
				},
			},
		},
	},
	-- ActivityWatch editor watcher: heartbeats the edited file, filetype, git
	-- branch and project into the aw-watcher-neovim_<host> bucket. The package is
	-- pinned in nix (nvim.nix), so lazy only has to resolve it out of the plugin
	-- root -- no download. `opts = {}` is required by the plugin even when empty.
	{
		"lowitea/aw-watcher.nvim",
		event = "VeryLazy",
		opts = {
			aw_server = {
				host = "127.0.0.1",
				port = 5600,
			},
		},
		config = function(_, opts)
			require("aw_watcher").setup(opts)
			-- The plugin fills branch/project from FileType/BufEnter/FocusGained,
			-- all of which already fired for the buffer opened at startup. Seed them
			-- once so the first file of a session isn't reported without a project.
			local utils = require("aw_watcher.utils")
			utils.set_branch_name()
			utils.set_project_name()
		end,
	},
	-- Suppress nvim 0.12 + noice incompatibility: vim._with fires cmdline_block_append
	-- events via :append during BufReadPost which noice's handler can't handle safely.
	{
		"folke/noice.nvim",
		opts = {
			routes = {
				{
					filter = { event = "msg_show", find = "Vim%(append%)" },
					opts = { skip = true },
				},
			},
		},
	},
	-- venv-selector: pick Python virtualenv (LazyVim python extra includes this).
	{
		"linux-cultist/venv-selector.nvim",
		keys = {
			{ "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
		},
	},
	-- Move flash.treesitter off S so surround can use it
	{
		"folke/flash.nvim",
		keys = {
			{ "S", false, mode = { "n", "o", "x" } },
			{ "gS", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
		},
	},
	-- nvim-surround: ys/ds/cs/S for surround operations
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup()
		end,
	},
}

local root = vim.fn.expand("~/.local/share/vim-plugins")
vim.opt.rtp:prepend(root .. "/lazy.nvim")

local util = require("lazy.core.util")
local ls = util.ls

util.ls = function(path, fn)
	return ls(path, function(fname, name, t)
		if path == root and t == "link" then
			t = "directory"
		end
		return fn(fname, name, t)
	end)
end

local is_cp = os.getenv("CP_ENV") == "1"

local plugins = {
	{
		"LazyVim/LazyVim",
		dir = root .. "/LazyVim",
		import = "lazyvim.plugins",
		opts = { colorscheme = "vscode" },
	},
	{
		"Mofiqul/vscode.nvim",
		dir = root .. "/vscode.nvim",
		lazy = false,
		priority = 1000,
		opts = { transparent = true },
	},
	{
		"catppuccin/nvim",
		dir = root .. "/catppuccin",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
	},
	{
		"folke/snacks.nvim",
		opts = {
			image = { enabled = true },
			indent = {
				animate = { enabled = false },
			},
		},
	},
	{ import = "lazyvim.plugins.extras.lang.python" },
	{ import = "lazyvim.plugins.extras.lang.typescript" },
	{ import = "lazyvim.plugins.extras.lang.json" },
	{ import = "lazyvim.plugins.extras.lang.yaml" },
	{ import = "lazyvim.plugins.extras.lang.toml" },
	{ import = "lazyvim.plugins.extras.lang.docker" },
	{ import = "lazyvim.plugins.extras.lang.sql" },
	{ import = "lazyvim.plugins.extras.lang.prisma" },
	{ import = "lazyvim.plugins.extras.lang.php" },
	{ import = "lazyvim.plugins.extras.lang.go" },
	{ import = "lazyvim.plugins.extras.lang.rust" },
	{ import = "lazyvim.plugins.extras.lang.java" },
	{ import = "lazyvim.plugins.extras.lang.clangd" },
	{ import = "lazyvim.plugins.extras.lang.terraform" },
	{ import = "lazyvim.plugins.extras.lang.helm" },
	{ import = "lazyvim.plugins.extras.lang.markdown" },
	{ import = "lazyvim.plugins.extras.lang.nix" },
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
	{ "nvim-treesitter/nvim-treesitter", enabled = false },
	{ import = "user.plugins" },
}

vim.list_extend(plugins, {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		opts = function(_, opts)
			opts.transparent_background = true
			return opts
		end,
	},
	{ import = "lazyvim.plugins.extras.ai.sidekick" },
	-- Configure codex CLI with dangerously-bypass-approvals flag
	{
		"folke/sidekick.nvim",
		opts = function(_, opts)
			opts.cli = opts.cli or {}
			opts.cli.tools = opts.cli.tools or {}
			opts.cli.tools.codex = vim.tbl_deep_extend("force", opts.cli.tools.codex or {}, {
				cmd = { "codex", "--dangerously-bypass-approvals-and-sandbox" },
				resume = { "resume" },
			})
			return opts
		end,
	},
	-- Local plugin: multi-group terminal manager
	{
		dir = vim.fn.stdpath("config") .. "/plugins/terminal.nvim",
		lazy = false,
		config = function()
			require("terminal").setup()
		end,
	},
})

require("lazy").setup(plugins, {
	root = root,
	install = { missing = false, colorscheme = {} },
	checker = { enabled = false },
	change_detection = { enabled = false, notify = false },
	rocks = { enabled = false },
	pkg = { enabled = false },
})

require("user.theme").setup()

for _, path in ipairs(vim.fn.glob(root .. "/nvim-treesitter-grammar-*", false, true)) do
	vim.opt.rtp:append(path)
end

-- Setup filetype detection for Helm
vim.filetype.add({
	pattern = {
		-- Helm values files: values.yaml, values*.yaml
		[".*values.*%.ya?ml$"] = function(path)
			if type(path) ~= "string" or path == "" then
				return "yaml"
			end

			local dir = vim.fn.fnamemodify(path, ":h")
			if type(dir) ~= "string" or dir == "" then
				return "yaml"
			end

			-- Check if it's in a helm context (has Chart.yaml nearby)
			local ok, chart = pcall(vim.fn.findfile, "Chart.yaml", dir .. "/;")
			if ok and chart ~= "" then
				return "yaml.helm-values"
			end

			return "yaml"
		end,
		-- Helm template files: templates/*.yaml
		[".*templates/.*%.ya?ml$"] = "helm",
	},
})

-- Keybindings (see keymaps.lua)
require("user.keymaps")

-- Competitive programming commands and keymaps (only when CP_ENV=1)
if is_cp then
	require("user.config.competitive_programming")
end

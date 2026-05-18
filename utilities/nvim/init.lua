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

require("lazy").setup({
	{
		"LazyVim/LazyVim",
		dir = root .. "/LazyVim",
		import = "lazyvim.plugins",
		opts = { colorscheme = "vscode" },
	},
	{ "Mofiqul/vscode.nvim", dir = root .. "/vscode.nvim", lazy = false, priority = 1000 },
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
}, {
	root = root,
	install = { missing = false, colorscheme = {} },
	checker = { enabled = false },
	change_detection = { enabled = false, notify = false },
	rocks = { enabled = false },
	pkg = { enabled = false },
})

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

-- Keybindings
-- Snacks picker keybindings
vim.keymap.set("n", "<leader>f", function() require("snacks").picker.files() end, { desc = "Find files" })
vim.keymap.set("n", "<leader>t", function() require("snacks").picker.grep() end, { desc = "Live grep" })

-- Terminal keybindings
vim.keymap.set({ "n", "t" }, "<C-\\>", function() require("snacks").terminal() end, { desc = "Toggle terminal" })

-- Buffer navigation
vim.keymap.set("n", "<TAB>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-TAB>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "X", function() require("snacks").bufdelete() end, { silent = true, desc = "Close buffer" })

-- Window navigation (normal mode)
vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true })

-- Window navigation (terminal mode)
vim.keymap.set("t", "<C-h>", "<C-\\><C-N><C-w>h", { noremap = true })
vim.keymap.set("t", "<C-j>", "<C-\\><C-N><C-w>j", { noremap = true })
vim.keymap.set("t", "<C-k>", "<C-\\><C-N><C-w>k", { noremap = true })
vim.keymap.set("t", "<C-l>", "<C-\\><C-N><C-w>l", { noremap = true })

-- LSP keybindings
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
vim.keymap.set("n", "<leader>sh", vim.lsp.buf.signature_help, { desc = "Signature help" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostics" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

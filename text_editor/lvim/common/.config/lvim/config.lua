-- +---------+
-- | general |
-- +---------+
vim.opt.relativenumber = true
vim.opt.sidescrolloff = 2
lvim.log.level = "warn"
lvim.format_on_save = true

-- +-------+
-- | theme |
-- +-------+
lvim.colorscheme = "darkplus"
-- lvim.colorscheme = "solarized"
-- lvim.colorscheme = "github_light"

-- +------------------------------------------------------------+
-- | keymappings [view all the defaults by pressing <leader>Lk] |
-- +------------------------------------------------------------+
lvim.leader = "space"

-- bufferline {{{
lvim.keys.normal_mode["<TAB>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-TAB>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<S-x>"] = ":BufferKill<CR>"
lvim.keys.normal_mode["<C-t>"] = ":ToggleTerm<CR>"
-- }}}

-- unmap a default keymapping {{{
lvim.keys.normal_mode["<S-l>"] = false
lvim.keys.normal_mode["<S-h>"] = false
lvim.keys.insert_mode["jk"] = false
lvim.keys.insert_mode["kj"] = false
lvim.keys.insert_mode["jj"] = false
-- }}}

-- lsp {{{
lvim.keys.normal_mode["<C-M-l>"] = "<cmd>lua vim.lsp.buf.formatting()<CR>"
-- }}}

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet. {{{

-- override default theme and show_previewer options
local function get_pickers(actions)
	return {
		find_files = {
			hidden = true,
		},
		live_grep = {
			--@usage don't include the filename in the search results
			only_sort_text = true,
		},
		grep_string = {
			only_sort_text = true,
		},
		buffers = {
			initial_mode = "normal",
			mappings = {
				i = {
					["<C-d>"] = actions.delete_buffer,
				},
				n = {
					["dd"] = actions.delete_buffer,
				},
			},
		},
		planets = {
			show_pluto = true,
			show_moon = true,
		},
		git_files = {
			hidden = true,
			show_untracked = true,
		},
		lsp_references = {
			initial_mode = "normal",
		},
		lsp_definitions = {
			initial_mode = "normal",
		},
		lsp_declarations = {
			initial_mode = "normal",
		},
		lsp_implementations = {
			initial_mode = "normal",
		},
	}
end

local _, actions = pcall(require, "telescope.actions")
lvim.builtin.telescope.defaults.mappings = {
	-- for input mode
	i = {
		["<C-j>"] = actions.move_selection_next,
		["<C-k>"] = actions.move_selection_previous,
		["<C-n>"] = actions.cycle_history_next,
		["<C-p>"] = actions.cycle_history_prev,
	},
	-- for normal mode
	n = {
		["<C-j>"] = actions.move_selection_next,
		["<C-k>"] = actions.move_selection_previous,
	},
}
-- }}}

-- Use which-key to add extra bindings with the leader-key prefix {{{
lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects <<CR>", "Projects" }
lvim.builtin.which_key.mappings["t"] = { "<cmd>Telescope live_grep <CR>", "Live Grep" }
lvim.builtin.which_key.mappings["f"] = { "<cmd>Telescope git_files <CR>", "Git File" }
lvim.builtin.which_key.mappings["F"] = { "<cmd>Telescope file_files <CR>", "File File" }

lvim.builtin.which_key.mappings["c"] = {
	name = "Competitive Programming",
	b = { "<cmd>Runscript<cr>", "Build and Run" },
	r = { "<cmd>RunWithTerm<cr>", "Build and Run in Terminal" },
	d = { "<cmd>RunWithDebug<cr>", "Build and Run in Debug Mode" },
	t = { "<cmd>TaskConfig<cr>", "Edit Task Info" },
	a = { "<cmd>ArchiveTask<cr>", "Archive Task" },
	n = { "<cmd>NewTask<cr>", "New Task" },
}
-- }}}

-- +---------------+
-- | plugin config |
-- +---------------+
lvim.builtin.terminal.active = true
lvim.builtin.bufferline.options.close_command = "Bdelete! %d"

-- telescope{{{
lvim.builtin.telescope.defaults.layout_config.width = 0.9
lvim.builtin.telescope.defaults.path_display = { shorten = 20 }
lvim.builtin.telescope.pickers = get_pickers(actions)
-- }}}

-- vsnip {{{
require("luasnip.loaders.from_vscode").load({ paths = { "~/.vsnip/" } })
-- }}}

-- terminal {{{
lvim.builtin.terminal.active = true

-- no shading
lvim.builtin.terminal.shade_terminals = 1

-- terminal's size as an functions
lvim.builtin.terminal.size = function(term)
	if term.direction == "horizontal" then
		return 15
	elseif term.direction == "vertical" then
		return math.min(120, math.max(vim.o.columns - 130, 35))
	else
		return 20
	end
end

lvim.builtin.terminal.highlights = {
	-- highlights which map to a highlight group name and a table of it's values
	-- NOTE: this is only a subset of values, any group placed here will be set for the terminal window split
	Normal = {
		link = "Normal",
	},
	NormalFloat = {
		link = "Normal",
	},
}
lvim.builtin.terminal.float_opts = {
	border = "single",
}

lvim.builtin.terminal.shell = "sh"
-- }}}

-- treesitter {{{
lvim.builtin.treesitter.ensure_installed = {
	"bash",
	"c",
	"cpp",
	"javascript",
	"json",
	"lua",
	"python",
	"typescript",
	"css",
	"rust",
	"java",
	"yaml",
	"latex",
}
lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true
-- }}}

-- +-----+
-- | lsp |
-- +-----+

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

-- formatters {{{
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{ exe = "markdownlint", filetypes = { "markdown" } },
	{ exe = "black", filetypes = { "python" } },
	{ exe = "isort", filetypes = { "python" } },
	{ exe = "stylua", filetypes = { "lua" } },
	{ exe = "shfmt", filetypes = { "sh" } },
	{ exe = "rustfmt", filetypes = { "rust" } },
	{ exe = "latexindent", filetypes = { "tex" } },
	{
		exe = "prettier",
		---@usage arguments to pass to the formatter
		-- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
		args = { "--print-with", "120" },
		---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
		filetypes = { "typescript", "typescriptreact", "css", "html" },
	},
})
-- }}}

-- linters {{{
local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
	{ exe = "write-good", filetypes = { "markdown", "txt" } },
	{ exe = "markdownlint", filetypes = { "markdown" } },
	{ exe = "flake8", filetypes = { "python" } },
	{ exe = "chktex", filetypes = { "tex" } },
	{
		exe = "shellcheck",
		args = { "--severity", "warning" },
		filetypes = { "sh", "bash" },
	},
	{
		exe = "codespell",
		filetypes = { "javascript", "python" },
	},
})
-- }}}

-- +--------------------+
-- | additional plugins |
-- +--------------------+
lvim.plugins = {
	{ "projekt0n/github-nvim-theme" },
	{ "shaunsingh/solarized.nvim" },
	{
		"zbirenbaum/copilot.lua",
		event = { "VimEnter" },
		config = function()
			vim.defer_fn(function()
				require("copilot").setup()
			end, 100)
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},
	{ "martinsione/darkplus.nvim" },
	{ "moll/vim-bbye" },
	{
		"folke/trouble.nvim",
		config = function()
			local present, trouble = pcall(require, "trouble")
			local M = { setup = function() end }
			if not present then
				return M
			end
			M.setup = function()
				trouble.setup({
					position = "bottom", -- position of the list can be: bottom, top, left, right
					height = 10, -- height of the trouble list when position is top or bottom
					width = 50, -- width of the list when position is left or right
					icons = true, -- use devicons for filenames
					mode = "workspace_diagnostics", -- "lsp_workspace_diagnostics", "lsp_document_diagnostics", "quickfix", "lsp_references", "loclist"
					fold_open = "", -- icon used for open folds
					fold_closed = "", -- icon used for closed folds
					group = true, -- group results by file
					padding = true, -- add an extra new line on top of the list
					action_keys = { -- key mappings for actions in the trouble list
						-- map to {} to remove a mapping, for example:
						-- close = {},
						close = "q", -- close the list
						cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
						refresh = "r", -- manually refresh
						jump = { "<cr>", "<tab>" }, -- jump to the diagnostic or open / close folds
						open_split = { "<c-x>" }, -- open buffer in new split
						open_vsplit = { "<c-v>" }, -- open buffer in new vsplit
						open_tab = { "<c-t>" }, -- open buffer in new tab
						jump_close = { "o" }, -- jump to the diagnostic and close the list
						toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
						toggle_preview = "P", -- toggle auto_preview
						hover = "K", -- opens a small popup with the full multiline message
						preview = "p", -- preview the diagnostic location
						close_folds = { "zM", "zm" }, -- close all folds
						open_folds = { "zR", "zr" }, -- open all folds
						toggle_fold = { "zA", "za" }, -- toggle fold of current file
						previous = "k", -- preview item
						next = "j", -- next item
					},
					indent_lines = true, -- add an indent guide below the fold icons
					auto_open = false, -- automatically open the list when you have diagnostics
					auto_close = false, -- automatically close the list when you have no diagnostics
					auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
					auto_fold = false, -- automatically fold a file trouble list at creation
					auto_jump = { "lsp_definitions" }, -- for the given modes, automatically jump if there is only a single result
					signs = {
						-- icons / text used for a diagnostic
						error = "",
						warning = "",
						hint = "",
						information = "",
						other = "﫠",
					},
					use_lsp_diagnostic_signs = false, -- enabling this will use the signs defined in your lsp client
				})
			end
			M.setup()
		end,
		cmd = "TroubleToggle",
	},
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
			local present, colorizer = pcall(require, "colorizer")
			local M = { setup = function() end }
			if not present then
				return M
			end
			M.setup = function()
				colorizer.setup({ "*" }, {
					RGB = true, -- #RGB hex codes
					RRGGBB = true, -- #RRGGBB hex codes
					RRGGBBAA = true, -- #RRGGBBAA hex codes
					rgb_fn = true, -- CSS rgb() and rgba() functions
					hsl_fn = true, -- CSS hsl() and hsla() functions
					css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
					css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
				})
			end
			M.setup()
		end,
	},
	{ "tpope/vim-surround" },
	{
		-- markdown
		"iamcco/markdown-preview.nvim",
		run = "cd app && yarn install",
		config = function()
			vim.cmd([[source $HOME/.config/lvim/markdown-preview.vim]])
		end,
	},
	{
		"lervag/vimtex",
		config = function()
			vim.cmd([[
        call vimtex#init()
        let g:tex_flavor='latex'
        let g:vimtex_view_method='zathura'
        let g:vimtex_view_general_viewer = 'zathura'
        let g:vimtex_quickfix_mode=0
        let g:vimtex_view_automatic = 0
      ]])
		end,
	},
	{
		"danymat/neogen",
		config = function()
			require("neogen").setup({})
		end,
		requires = "nvim-treesitter/nvim-treesitter",
	},
	{
		"alexghergh/nvim-tmux-navigation",
		config = function()
			require("nvim-tmux-navigation").setup({
				disable_when_zoomed = true, -- defaults to false
				keybindings = {
					left = "<C-h>",
					down = "<C-j>",
					up = "<C-k>",
					right = "<C-l>",
					last_active = "<C-\\>",
					next = "<C-Space>",
				},
			})
		end,
	},
}

-- +--------------------------------------------------------+
-- | autocommands (https://neovim.io/doc/user/autocmd.html) |
-- +--------------------------------------------------------+

-- general {{{
vim.api.nvim_create_autocmd("VimEnter", { pattern = { "*" }, command = ':silent exec "!kill -s SIGWINCH $PPID"' })
vim.api.nvim_create_autocmd("VimEnter", { pattern = { "*" }, command = "highlight SignColumn guibg=NONE" })
vim.api.nvim_create_autocmd("BufEnter", { pattern = { "*" }, command = "highlight BufferLineFill guibg=NONE" })
vim.api.nvim_create_autocmd("BufEnter", { pattern = { "*" }, command = "highlight ToggleTerm1SignColumn guibg=NONE" })
-- }}}

-- suckless {{{
vim.api.nvim_create_autocmd("VimEnter", {
	pattern = { "*.h" },
	callback = function()
		require("lvim.core.autocmds").disable_format_on_save()
	end,
})
-- }}}

-- +----+
-- | cp |
-- +----+
vim.cmd([[source $HOME/.config/lvim/cp.vim]])

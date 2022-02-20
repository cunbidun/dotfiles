-- +---------+
-- | general |
-- +---------+

vim.opt.relativenumber = true -- show line numbers relatively

lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "nord"

-- +------------------------------------------------------------+
-- | keymappings [view all the defaults by pressing <leader>Lk] |
-- +------------------------------------------------------------+

lvim.leader = "space"

-- bufferline
lvim.keys.normal_mode["<TAB>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-TAB>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<S-x>"] = ":BufferKill<CR>"

-- unmap a default keymapping
lvim.keys.normal_mode["<S-l>"] = false
lvim.keys.normal_mode["<S-h>"] = false
lvim.keys.insert_mode["jk"] = false
lvim.keys.insert_mode["kj"] = false
lvim.keys.insert_mode["jj"] = false

-- lsp
lvim.keys.normal_mode["<C-M-l>"] = "<cmd>lua vim.lsp.buf.formatting()<CR>"
lvim.keys.normal_mode["<leader>rn"] = "<cmd>lua vim.lsp.buf.rename()<CR>"

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
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

lvim.builtin.telescope.defaults.layout_config.width = 0.9
lvim.builtin.telescope.defaults.path_display = { shorten = 20 }

-- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
lvim.builtin.which_key.mappings["t"] = { "<cmd>Telescope live_grep<CR>", "Live Grep" }
lvim.builtin.which_key.mappings["n"] = {
	name = "+Note",
	["#"] = {
		"<cmd>lua require('telekasten').show_tags()<cr>",
		"Search tag",
	},
	d = {
		"<cmd>lua require('telekasten').goto_today()<cr>",
		"Go to today's note",
	},
	f = {
		"<cmd>lua require('telekasten').follow_link()<cr>",
		"Find notes",
	},
	l = {
		"<cmd>lua require('telekasten').insert_link()<cr>",
		"Insert new link",
	},
	n = {
		"<cmd>lua require('telekasten').new_note()<cr>",
		"Create a new note",
	},
	r = {
		"<cmd>lua require('telekasten').rename_note()<cr>",
		"Rename note",
	},
	t = {
		"<cmd>lua require('telekasten').toggle_todo()<cr>",
		"Toggle todo",
	},
	w = {
		"<cmd>lua require('telekasten').goto_thisweek()<cr>",
		"Go to this week's note",
	},
}
-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = true
lvim.builtin.notify.active = true

-- +---------------+
-- | plugin config |
-- +---------------+

-- Telescope
lvim.builtin.telescope.pickers = { find_files = { find_command = { "rg", "--files", "--follow", "--hidden" } } }

lvim.builtin.dashboard.custom_section.a = {
	description = { "  Recent Projects    " },
	command = "Telescope projects",
}

lvim.builtin.dashboard.custom_section.b = {
	description = { "  Find File          " },
	command = "Telescope find_files",
}

lvim.builtin.dashboard.custom_section.c = {
	description = { "  New File           " },
	command = ":ene!",
}

-- load vsnip
require("luasnip.loaders.from_vscode").load({ paths = { "~/.vsnip/" } })

-- +----------+
-- | terminal |
-- +----------+
lvim.builtin.terminal.active = true
-- lvim.builtin.terminal.float_opts = {
-- 	border = "single",
-- 	-- highlights = { border = "Nord9", background = "Nord0" },
-- }

-- no shading
lvim.builtin.terminal.shade_terminals = false

-- terminal's size as an functions
lvim.builtin.terminal.size = function(term)
	if term.direction == "horizontal" then
		return 15
	elseif term.direction == "vertical" then
		if vim.o.columns < 150 then
			return vim.o.columns * 0.35
		else
			return vim.o.columns * 0.4
		end
	else
		return 20
	end
end

-- terminal's shell
lvim.builtin.terminal.shell = "sh"

-- +----------+
-- | nvimtree |
-- +----------+
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.show_icons.git = 0

-- +------------+
-- | treesitter |
-- +------------+
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

-- +-----+
-- | lsp |
-- +-----+
-- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{ exe = "markdownlint", filetypes = { "markdown" } },
	{ exe = "black", filetypes = { "python" } },
	{ exe = "isort", filetypes = { "python" } },
	{ exe = "stylua", filetypes = { "lua" } },
	{ exe = "shfmt", filetypes = { "sh" } },
	{ exe = "latexindent", filetypes = { "tex" } },
	{
		exe = "prettier",
		---@usage arguments to pass to the formatter
		-- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
		args = { "--print-with", "100" },
		---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
		filetypes = { "typescript", "typescriptreact", "css" },
	},
})

-- set additional linters
local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
	{ exe = "write-good", filetypes = { "markdown", "txt" } },
	-- { exe = "markdownlint", filetypes = { "markdown" } },
	{ exe = "flake8", filetypes = { "python" } },
	{ exe = "chktex", filetypes = { "tex" } },
	{
		exe = "shellcheck",
		args = { "--severity", "warning" },
	},
	{
		exe = "codespell",
		filetypes = { "javascript", "python" },
	},
})

-- Additional Plugins
lvim.plugins = {
	{ "arcticicestudio/nord-vim" },
	{
		"cunbidun/trouble.nvim",
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
		"karb94/neoscroll.nvim",
		config = function()
			local present, neoscroll = pcall(require, "neoscroll")
			local M = { setup = function() end }
			if not present then
				return M
			end
			M.setup = function()
				neoscroll.setup({
					-- All these keys will be mapped to their corresponding default scrolling animation
					mappings = {
						"<C-u>",
						"<C-d>",
						"<C-y>",
						"<C-e>",
						"zt",
						"zz",
						"zb",
					},
					hide_cursor = true, -- Hide cursor while scrolling
					stop_eof = true, -- Stop at <EOF> when scrolling downwards
					use_local_scrolloff = false, -- Use the local scope of scrolloff instead of the global scope
					respect_scrolloff = false, -- Stop scrolling when the cursor reaches the scrolloff margin of the file
					cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
					easing_function = nil, -- Default easing function
					pre_hook = nil, -- Function to run before the scrolling animation starts
					post_hook = nil, -- Function to run after the scrolling animation ends
				})
				local t = {}
				t["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "150" } }
				t["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "150" } }
				t["<C-y>"] = { "scroll", { "-0.10", "false", "100" } }
				t["<C-e>"] = { "scroll", { "0.10", "false", "100" } }
				t["zt"] = { "zt", { "250" } }
				t["zz"] = { "zz", { "250" } }
				t["zb"] = { "zb", { "250" } }
				require("neoscroll.config").set_mappings(t)
			end
			M.setup()
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			local present, indent_blankline = pcall(require, "indent_blankline")
			local M = { setup = function() end }
			if not present then
				return M
			end
			M.setup = function()
				indent_blankline.setup({
					indentLine_enabled = 1,
					char = "▏",
					filetype_exclude = {
						"help",
						"terminal",
						"dashboard",
						"packer",
						"lspinfo",
						"TelescopePrompt",
						"TelescopeResults",
					},
					buftype_exclude = { "terminal" },
					show_trailing_blankline_indent = false,
					show_first_indent_level = false,
					show_current_context = true,
					use_treesitter = true,
				})
				vim.g.indent_blankline_context_patterns = {
					"^for",
					"^if",
					"^object",
					"^table",
					"^while",
					"arguments",
					"block",
					"catch_clause",
					"class",
					"else_clause",
					"function",
					"if_statement",
					"import_statement",
					"jsx_element",
					"jsx_element",
					"jsx_self_closing_element",
					"method",
					"operation_type",
					"return",
					"try_statement",
				}
				vim.g.indent_blankline_use_treesitter = true
			end
			M.setup()
		end,
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
			vim.cmd([[source $HOME/dotfiles/nvim/.config/nvim/lua/plugins/configs/markdown-preview.vim]])
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
		"renerocksai/telekasten.nvim",
		config = function()
			local home = vim.fn.expand("~/zettelkasten")

			require("telekasten").setup({
				home = home,

				-- if true, telekasten will be enabled when opening a note within the configured home
				take_over_my_home = true,

				-- auto-set telekasten filetype: if false, the telekasten filetype will not be used
				--                               and thus the telekasten syntax will not be loaded either
				auto_set_filetype = true,

				-- dir names for special notes (absolute path or subdir name)
				dailies = home .. "/" .. "daily",
				weeklies = home .. "/" .. "weekly",
				templates = home .. "/" .. "templates",

				-- image (sub)dir for pasting
				-- dir name (absolute path or subdir name)
				-- or nil if pasted images shouldn't go into a special subdir
				image_subdir = "img",

				-- markdown file extension
				extension = ".md",

				-- following a link to a non-existing note will create it
				follow_creates_nonexisting = true,
				dailies_create_nonexisting = true,
				weeklies_create_nonexisting = true,

				-- template for new notes (new_note, follow_link)
				-- set to `nil` or do not specify if you do not want a template
				template_new_note = home .. "/" .. "templates/new_note.md",

				-- template for newly created daily notes (goto_today)
				-- set to `nil` or do not specify if you do not want a template
				template_new_daily = home .. "/" .. "templates/daily.md",

				-- template for newly created weekly notes (goto_thisweek)
				-- set to `nil` or do not specify if you do not want a template
				template_new_weekly = home .. "/" .. "templates/weekly.md",

				-- image link style
				-- wiki:     ![[image name]]
				-- markdown: ![](image_subdir/xxxxx.png)
				image_link_style = "markdown",

				-- integrate with calendar-vim
				plug_into_calendar = true,
				calendar_opts = {
					-- calendar week display mode: 1 .. 'WK01', 2 .. 'WK 1', 3 .. 'KW01', 4 .. 'KW 1', 5 .. '1'
					weeknm = 4,
					-- use monday as first day of week: 1 .. true, 0 .. false
					calendar_monday = 1,
					-- calendar mark: where to put mark for marked days: 'left', 'right', 'left-fit'
					calendar_mark = "left-fit",
				},

				-- telescope actions behavior
				close_after_yanking = false,
				insert_after_inserting = true,

				-- tag notation: '#tag', ':tag:', 'yaml-bare'
				tag_notation = "#tag",

				-- command palette theme: dropdown (window) or ivy (bottom panel)
				command_palette_theme = "ivy",

				-- tag list theme:
				-- get_cursor: small tag list at cursor; ivy and dropdown like above
				show_tags_theme = "ivy",

				-- when linking to a note in subdir/, create a [[subdir/title]] link
				-- instead of a [[title only]] link
				subdirs_in_links = true,

				-- template_handling
				-- What to do when creating a new note via `new_note()` or `follow_link()`
				-- to a non-existing note
				-- - prefer_new_note: use `new_note` template
				-- - smart: if day or week is detected in title, use daily / weekly templates (default)
				-- - always_ask: always ask before creating a note
				template_handling = "smart",

				-- path handling:
				--   this applies to:
				--     - new_note()
				--     - new_templated_note()
				--     - follow_link() to non-existing note
				--
				--   it does NOT apply to:
				--     - goto_today()
				--     - goto_thisweek()
				--
				--   Valid options:
				--     - smart: put daily-looking notes in daily, weekly-looking ones in weekly,
				--              all other ones in home, except for notes/with/subdirs/in/title.
				--              (default)
				--
				--     - prefer_home: put all notes in home except for goto_today(), goto_thisweek()
				--                    except for notes with subdirs/in/title.
				--
				--     - same_as_current: put all new notes in the dir of the current note if
				--                        present or else in home
				--                        except for notes/with/subdirs/in/title.
				new_note_location = "smart",

				-- should all links be updated when a file is renamed
				rename_update_links = true,
			})
		end,
	},
}

vim.cmd([[
  autocmd VimEnter * :silent exec "!kill -s SIGWINCH $PPID"
]])

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
lvim.autocommands.custom_groups = {
	{ "BufWinEnter", "*.lua", "setlocal ts=2 sw=2" },

	{ "VimEnter", "*", "highlight Normal ctermbg=NONE guibg=NONE" },
	{ "VimEnter", "*", "highlight SignColumn guibg=NONE" },

	-- zettelkasten
	{ "VimEnter", "*", "highlight tkTagSep ctermfg=gray guifg=gray" },
	{ "VimEnter", "*", "highlight tkTag ctermfg=175 guifg=#A3BE8C" },
	{ "VimEnter", "*", "hi tklink ctermfg=72 guifg=#A3BE8C cterm=bold,underline gui=bold,underline" },
	{ "FileType", "telekasten", "set filetype=telekasten.markdown" },

	-- colorscheme
	{ "VimEnter", "*", "highlight Nord0 guibg=#2E3440" },
	{ "VimEnter", "*", "highlight Nord1 guibg=#3B4252" },
	{ "VimEnter", "*", "highlight Nord2 guibg=#434C5E" },
	{ "VimEnter", "*", "highlight Nord3 guibg=#4C566A" },
	{ "VimEnter", "*", "highlight Nord4 guibg=#D8DEE9" },
	{ "VimEnter", "*", "highlight Nord5 guibg=#E5E9F0" },
	{ "VimEnter", "*", "highlight Nord6 guibg=#ECEFF4" },
	{ "VimEnter", "*", "highlight Nord7 guibg=#8FBCBB" },
	{ "VimEnter", "*", "highlight Nord8 guibg=#88C0D0" },
	{ "VimEnter", "*", "highlight Nord9 guibg=#81A1C1" },
	{ "VimEnter", "*", "highlight Nord10 guibg=#5E81AC" },
	{ "VimEnter", "*", "highlight Nord11 guibg=#BF616A" },
	{ "VimEnter", "*", "highlight Nord12 guibg=#D08770" },
	{ "VimEnter", "*", "highlight Nord13 guibg=#EBCB8B" },
	{ "VimEnter", "*", "highlight Nord14 guibg=#A3BE8C" },
	{ "VimEnter", "*", "highlight Nord15 guibg=#B48EAD" },

	-- nvim-notify
	{ "VimEnter", "*", "highlight NotifyERRORBorder guifg=#BF616A" },
	{ "VimEnter", "*", "highlight NotifyWARNBorder guifg=#EBCB8B" },
	{ "VimEnter", "*", "highlight NotifyINFOBorder guifg=#A3BE8C" },
	{ "VimEnter", "*", "highlight NotifyDEBUGBorder guifg=#81A1C1" },
	{ "VimEnter", "*", "highlight NotifyTRACEBorder guifg=#B48EAD" },

	{ "VimEnter", "*", "highlight NotifyERRORIcon guifg=#BF616A" },
	{ "VimEnter", "*", "highlight NotifyWARNIcon guifg=#EBCB8B" },
	{ "VimEnter", "*", "highlight NotifyINFOIcon guifg=#A3BE8C" },
	{ "VimEnter", "*", "highlight NotifyDEBUGIcon guifg=#81A1C1" },
	{ "VimEnter", "*", "highlight NotifyTRACEIcon guifg=#B48EAD" },

	{ "VimEnter", "*", "highlight NotifyERRORTitle  guifg=#BF616A" },
	{ "VimEnter", "*", "highlight NotifyWARNTitle guifg=#EBCB8B" },
	{ "VimEnter", "*", "highlight NotifyINFOTitle guifg=#A3BE8C" },
	{ "VimEnter", "*", "highlight NotifyDEBUGTitle  guifg=#81A1C1" },
	{ "VimEnter", "*", "highlight NotifyTRACETitle  guifg=#B48EAD" },

	{ "VimEnter", "*", "highlight link NotifyERRORBody Nord1" },
	{ "VimEnter", "*", "highlight link NotifyWARNBody Nord1" },
	{ "VimEnter", "*", "highlight link NotifyINFOBody Nord1" },
	{ "VimEnter", "*", "highlight link NotifyDEBUGBody Nord1" },
	{ "VimEnter", "*", "highlight link NotifyTRACEBody Nord1" },

	-- trouble.nvim
	{ "VimEnter", "*", "highlight  TroubleCount guifg=#EBCB8B guibg=#434C5E" },

	-- dwm, disable format_on_save
	{ "VimEnter", "config.*", "lua require('lvim.core.autocmds').disable_format_on_save()" },
	{ "VimEnter", "dwm.c", "lua require('lvim.core.autocmds').disable_format_on_save()" },
	{ "VimEnter", "dmenu.c", "lua require('lvim.core.autocmds').disable_format_on_save()" },
}

-- CP
vim.cmd([[source $HOME/.config/lvim/cp.vim]])

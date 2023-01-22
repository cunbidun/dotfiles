local _, telescope_actions = pcall(require, "telescope.actions")

-- override default theme and show_previewer options
local function get_pickers(input_action)
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
					["<C-d>"] = input_action.delete_buffer,
				},
				n = {
					["dd"] = input_action.delete_buffer,
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

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet. {{{
lvim.builtin.telescope.defaults.mappings = {
	-- for input mode
	i = {
		["<C-j>"] = telescope_actions.move_selection_next,
		["<C-k>"] = telescope_actions.move_selection_previous,
		["<C-n>"] = telescope_actions.cycle_history_next,
		["<C-p>"] = telescope_actions.cycle_history_prev,
	},
	-- for normal mode
	n = {
		["<C-j>"] = telescope_actions.move_selection_next,
		["<C-k>"] = telescope_actions.move_selection_previous,
	},
}
-- }}}

lvim.builtin.telescope.defaults.layout_config.width = 0.9
lvim.builtin.telescope.defaults.path_display = { shorten = 20 }
lvim.builtin.telescope.pickers = get_pickers(telescope_actions)
lvim.builtin.telescope.defaults.file_ignore_patterns = { "node_modules", ".git" }

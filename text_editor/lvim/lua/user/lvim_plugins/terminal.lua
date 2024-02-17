-- terminal {{{
lvim.builtin.terminal.active = true
lvim.builtin.bufferline.options.close_command = "Bdelete! %d"

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

lvim.builtin.terminal.shell = "zsh"
-- }}}

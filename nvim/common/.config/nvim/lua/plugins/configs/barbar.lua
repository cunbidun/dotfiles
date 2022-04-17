local M = {setup = function() end}

M.setup = function()
	vim.g.bufferline = {
		-- Enable/disable animations
		animation = false,

		-- If set, the icon color will follow its corresponding buffer
		-- highlight group. By default, the Buffer*Icon group is linked to the
		-- Buffer* group (see Highlighting below). Otherwise, it will take its
		-- default value as defined by devicons.
		icon_custom_colors = true,

		-- Enable/disable auto-hiding the tab bar when there is a single buffer
		auto_hide = false,

		-- Enable/disable current/total tabpages indicator (top right corner)
		tabpages = true,

		-- Enable/disable close button
		closable = false,

		-- Enables/disable clickable tabs
		--  - left-click: go to buffer
		--  - middle-click: delete buffer
		clickable = true,

		-- Enable/disable icons
		-- if set to 'numbers', will show buffer index in the tabline
		-- if set to 'both', will show buffer index and icons in the tabline
		icons = true,

		-- Sets the maximum padding width with which to surround each tab
		maximum_padding = 1,

		-- Sets the maximum buffer name length.
		maximum_length = 30,
	}

	vim.api.nvim_set_keymap('n', '<TAB>', ':BufferNext<CR>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<S-TAB>', ':BufferPrevious<CR>', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<S-x>', ':BufferClose<CR>', { noremap = true, silent = true })
end

return M
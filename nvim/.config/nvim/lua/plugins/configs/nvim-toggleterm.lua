local present, toggleterm = pcall(require, "toggleterm")

local M = { setup = function() end }

if not present then
	return M
end

M.setup = function()
	toggleterm.setup({
		direction = "float",
		-- size can be a number or function which is passed the current terminal
		size = function(term)
			if term.direction == "horizontal" then
				return 15
			elseif term.direction == "vertical" then
				return vim.o.columns * 0.4
		  else
        return 20
      end
		end,
		open_mapping = [[<c-t>]],
		hide_numbers = true, -- hide the number column in toggleterm buffers
		shade_filetypes = {},
		shade_terminals = false,
		shading_factor = "<number>", -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
		start_in_insert = false,
		insert_mappings = true, -- whether or not the open mapping applies in insert mode
		persist_size = true,
		close_on_exit = true, -- close the terminal window when the process exits
		shell = vim.o.shell, -- change the default shell
		-- This field is only relevant if direction is set to 'float'
		float_opts = {
			-- The border key is *almost* the same as 'nvim_win_open'
			-- see :h nvim_win_open for details on borders however
			-- the 'curved' border is a custom border type
			-- not natively supported but implemented in this plugin.
			border = "single",
			highlights = { border = "Nord9", background = "Nord0" },
		},
	})
	local Terminal = require("toggleterm.terminal").Terminal
	local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })

	function _lazygit_toggle()
		lazygit:toggle()
	end

	vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
end

return M

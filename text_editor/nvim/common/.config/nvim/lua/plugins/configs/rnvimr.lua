local M = {setup = function() end}

M.setup = function()
	vim.g.rnvimr_ex_enable = 0
	vim.g.rnvimr_draw_border = 1
	vim.g.rnvimr_pick_enable = 1
	vim.g.rnvimr_bw_enable = 1
	vim.api.nvim_set_keymap('n', '-', ':RnvimrToggle<CR>', {noremap = true, silent = true})
end

return M
local M = {setup = function() end}

M.setup = function()
	vim.cmd('highlight default link gitblame SpecialComment')
	vim.g.gitblame_enabled = 1
end

return M
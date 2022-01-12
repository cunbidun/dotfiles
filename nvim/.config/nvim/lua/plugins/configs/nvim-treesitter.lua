local present, treesitter = pcall(require, "nvim-treesitter.configs")

local M = { setup = function() end }

if not present then
	return M
end

M.setup = function()
	treesitter.setup({
		ensure_installed = "maintained",
		highlight = { enable = true },
		refactor = {
			highlight_definitions = { enable = true },
		},
	})
end

return M


local present1, autopairs = pcall(require, "nvim-autopairs")

local M = { setup = function() end }

if not present1 then
	return M
end

M.setup = function()
	autopairs.setup()
end

return M

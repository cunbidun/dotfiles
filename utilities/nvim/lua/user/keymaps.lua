-- Terminal (multi-group terminal manager)
local term = require("terminal")
vim.keymap.set({ "n", "t" }, "<C-\\>", term.toggle, { desc = "Terminal toggle" })
vim.keymap.set({ "n", "t" }, "<leader>ts", term.split, { desc = "Terminal split pane" })
vim.keymap.set({ "n", "t" }, "<leader>tn", term.new_group, { desc = "Terminal new group" })
vim.keymap.set({ "n", "t" }, "<leader>tl", term.next_group, { desc = "Terminal next group" })
vim.keymap.set({ "n", "t" }, "<leader>th", term.prev_group, { desc = "Terminal prev group" })
vim.keymap.set({ "n", "t" }, "<leader>ti", term.status, { desc = "Terminal status" })

-- Buffer navigation
vim.keymap.set("n", "<TAB>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-TAB>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "X", function()
	require("snacks").bufdelete()
end, { silent = true, desc = "Close buffer" })

-- Window navigation (terminal mode)
vim.keymap.set("t", "<C-h>", "<C-\\><C-N><C-w>h", { noremap = true })
vim.keymap.set("t", "<C-j>", "<C-\\><C-N><C-w>j", { noremap = true })
vim.keymap.set("t", "<C-k>", "<C-\\><C-N><C-w>k", { noremap = true })
vim.keymap.set("t", "<C-l>", "<C-\\><C-N><C-w>l", { noremap = true })

-- LSP
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
vim.keymap.set("n", "<leader>sh", vim.lsp.buf.signature_help, { desc = "Signature help" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show diagnostics" })

-- ---------------------------------------------------------------------------
-- Resize submode
-- <leader>R  → enter (toggle)
-- h / j / k / l → resize while active
-- <leader>R again → exit
-- ---------------------------------------------------------------------------
local resize_mode = false

local function exit_resize()
	resize_mode = false
	vim.notify("Resize mode off", vim.log.levels.INFO, { title = "Resize" })
end

local function resize_key(fallback, cmd)
	if resize_mode then
		vim.cmd(cmd)
		return ""
	end
	return fallback
end

vim.keymap.set("n", "<leader>R", function()
	if resize_mode then
		exit_resize()
	else
		resize_mode = true
		vim.notify(
			"Resize mode  h/j/k/l to grow splits · <leader>R to exit",
			vim.log.levels.INFO,
			{ title = "Resize" }
		)
	end
end, { desc = "Toggle resize mode" })

vim.keymap.set("n", "h", function()
	return resize_key("h", "vertical resize +5")
end, { expr = true, silent = true })
vim.keymap.set("n", "l", function()
	return resize_key("l", "vertical resize +5")
end, { expr = true, silent = true })
vim.keymap.set("n", "j", function()
	return resize_key("j", "resize +2")
end, { expr = true, silent = true })
vim.keymap.set("n", "k", function()
	return resize_key("k", "resize +2")
end, { expr = true, silent = true })

-- ---------------------------------------------------------------------------
-- Focused-panel indicator: dim inactive windows
-- ---------------------------------------------------------------------------
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
	callback = function()
		vim.wo.winhighlight = ""
		vim.wo.cursorline = true
	end,
})
vim.api.nvim_create_autocmd("WinLeave", {
	callback = function()
		vim.wo.winhighlight = "Normal:NormalNC,CursorLine:NormalNC"
		vim.wo.cursorline = false
	end,
})

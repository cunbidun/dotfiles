local cp_term_buf = nil

local function TermWrapper(command)
	vim.cmd("wa")

	local prev_win = vim.api.nvim_get_current_win()

	if cp_term_buf and vim.api.nvim_buf_is_valid(cp_term_buf) then
		vim.api.nvim_buf_delete(cp_term_buf, { force = true })
	end

	local term = Snacks.terminal(command, {
		win = {
			position = "right",
			keys = { q = false },
		},
		interactive = false,
	})
	cp_term_buf = term and term.buf or nil

	vim.api.nvim_set_current_win(prev_win)
end

vim.api.nvim_create_user_command("Runscript", function()
	TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --build', vim.fn.expand("%:p:h")))
end, {})

vim.api.nvim_create_user_command("RunWithDebug", function()
	TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --build-with-debug', vim.fn.expand("%:p:h")))
end, {})

vim.api.nvim_create_user_command("RunWithTerm", function()
	TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --build-with-term', vim.fn.expand("%:p:h")))
end, {})

vim.api.nvim_create_user_command("TaskConfig", function()
	TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --edit-problem-config', vim.fn.expand("%:p:h")))
end, {})

vim.api.nvim_create_user_command("ArchiveTask", function()
	TermWrapper(string.format('clear; cpcli_app task --root-dir="%s" --archive', vim.fn.expand("%:p:h")))
end, {})

vim.api.nvim_create_user_command("NewTask", function()
	TermWrapper("clear; cpcli_app project --new-task")
end, {})

vim.api.nvim_create_user_command("DeleteTask", function()
	TermWrapper(string.format('mv "%s" ~/.local/share/Trash/files/', vim.fn.expand("%:p:h")))
end, {})

vim.api.nvim_create_user_command("TaskFiles", function()
	Snacks.picker.files({
		cwd = "task",
		hidden = true,
		ignored = true,
		exclude = { "*.json", ".gitkeep", "*.dSYM" },
	})
end, {})

-- Register after VeryLazy so these override LazyVim's global keymaps
-- (<leader>cf = Format, <leader>cd = Line Diagnostics in lazyvim/config/keymaps.lua).
-- LSP buffer-local conflicts (<leader>ca, <leader>cr) are disabled via
-- nvim-lspconfig opts in user/plugins.lua — no LspAttach hack needed.
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	once = true,
	callback = function()
		require("which-key").add({
			{ "<leader>cb", "<cmd>Runscript<cr>",    desc = "Build and Run",             mode = "n" },
			{ "<leader>cr", "<cmd>RunWithTerm<cr>",  desc = "Build and Run in Terminal", mode = "n" },
			{ "<leader>cd", "<cmd>RunWithDebug<cr>", desc = "Build and Run in Debug",    mode = "n" },
			{ "<leader>ct", "<cmd>TaskConfig<cr>",   desc = "Edit Task Info",            mode = "n" },
			{ "<leader>ca", "<cmd>ArchiveTask<cr>",  desc = "Archive Task",              mode = "n" },
			{ "<leader>cf", "<cmd>TaskFiles<cr>",    desc = "Find Task Files",           mode = "n" },
			{ "<leader>cn", "<cmd>NewTask<cr>",      desc = "New Task",                  mode = "n" },
		})
	end,
})

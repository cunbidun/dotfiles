local function TermWrapper(command)
	vim.cmd("wa")

	local function get_terminal_buffers()
		local buffers = vim.api.nvim_list_bufs()
		local terminal_buffers = {}
		for _, buf in ipairs(buffers) do
			if vim.bo[buf].buftype == "terminal" then
				table.insert(terminal_buffers, buf)
			end
		end
		return terminal_buffers
	end

	local buf_id = get_terminal_buffers()
	if #buf_id > 0 then
		vim.cmd(string.format("bdelete! %s", buf_id[1]))
	end

	Snacks.terminal(command, {
		win = { position = "right" },
		start_insert = true,
		auto_insert = true,
	})
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
		matcher = {
			exclude = { "%.json$", "%.dSYM", "^%.gitkeep$" },
		},
	})
end, {})

require("which-key").add({
	{ "<leader>cb", "<cmd>Runscript<cr>",    desc = "Build and Run",              mode = "n", order = 1 },
	{ "<leader>cr", "<cmd>RunWithTerm<cr>",  desc = "Build and Run in Terminal",  mode = "n", order = 2 },
	{ "<leader>cd", "<cmd>RunWithDebug<cr>", desc = "Build and Run in Debug",     mode = "n", order = 3 },
	{ "<leader>ct", "<cmd>TaskConfig<cr>",   desc = "Edit Task Info",             mode = "n", order = 4 },
	{ "<leader>ca", "<cmd>ArchiveTask<cr>",  desc = "Archive Task",               mode = "n", order = 5 },
	{ "<leader>cf", "<cmd>TaskFiles<cr>",    desc = "Find Task Files",            mode = "n", order = 6 },
	{ "<leader>cn", "<cmd>NewTask<cr>",      desc = "New Task",                   mode = "n", order = 7 },
})

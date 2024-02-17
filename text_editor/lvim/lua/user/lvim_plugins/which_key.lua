-- Use which-key to add extra bindings with the leader-key prefix {{{
lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects <<CR>", "Projects" }
lvim.builtin.which_key.mappings["t"] = { "<cmd>Telescope live_grep <CR>", "Live Grep" }
lvim.builtin.which_key.mappings["f"] = { "<cmd>Telescope find_files<CR>", "File File" }

lvim.builtin.which_key.mappings["c"] = {
	name = "Competitive Programming",
	b = { "<cmd>Runscript<cr>", "Build and Run" },
	r = { "<cmd>RunWithTerm<cr>", "Build and Run in Terminal" },
	d = { "<cmd>RunWithDebug<cr>", "Build and Run in Debug Mode" },
	t = { "<cmd>TaskConfig<cr>", "Edit Task Info" },
	a = { "<cmd>ArchiveTask<cr>", "Archive Task" },
	n = { "<cmd>NewTask<cr>", "New Task" },
	f = { "<cmd>Easypick find_tasks<cr>", "Find Task" },
}
-- }}}

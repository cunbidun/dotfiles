local easypick = require("easypick")

easypick.setup({
	pickers = {
		-- list files inside current folder with default previewer
		{
			-- name for your custom picker, that can be invoked using :Easypick <name> (supports tab completion)
			name = "find_tasks",
			-- the command to execute, output has to be a list of plain text entries
			command = "find task archive  -type f ! -name '*.json'",
			-- specify your custom previwer, or use one of the easypick.previewers
			previewer = easypick.previewers.default(),
		},
	},
})

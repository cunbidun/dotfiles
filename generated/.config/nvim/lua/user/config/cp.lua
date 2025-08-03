print("loading cp.lua")

local function TermWrapper(command)
  vim.cmd("wa")

  local function get_terminal_buffers()
    local buffers = vim.api.nvim_list_bufs()
    local terminal_buffers = {}

    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
        table.insert(terminal_buffers, buf)
      end
    end

    return terminal_buffers
  end

  local buf_id = get_terminal_buffers()
  if #buf_id > 0 then
    vim.cmd(string.format("%sbdelete!", buf_id[1]))
  end

  vim.cmd(string.format("TermExec direction=vertical cmd='%s'", command))
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

local binds = {
  { action = "<cmd>Runscript<cr>", key = "<leader>cb", mode = "n", desc = "Build and Run" },
  { action = "<cmd>RunWithTerm<cr>", key = "<leader>cr", mode = "n", desc = "Build and Run in Terminal" },
  { action = "<cmd>RunWithDebug<cr>", key = "<leader>cd", mode = "n", desc = "Build and Run in Debug Mode" },
  { action = "<cmd>TaskConfig<cr>", key = "<leader>ct", mode = "n", desc = "Edit Task Info" },
  { action = "<cmd>ArchiveTask<cr>", key = "<leader>ca", mode = "n", desc = "Archive Task" },
  { action = "<cmd>TaskFiles<CR>", key = "<leader>cf", mode = "n", desc = "Find Task Files" },
  { action = "<cmd>NewTask<cr>", key = "<leader>cn", mode = "n", desc = "New Task" },
}

for _, map in ipairs(binds) do
  vim.keymap.set(map.mode, map.key, map.action, map.options)
end

local function find_task_files()
  require("telescope.builtin").find_files({
    prompt_title = "Task Files",
    find_command = {
      "find",
      "task",
      "-type",
      "f",
      "!",
      "-name",
      "*.json",
      "!",
      "-path",
      "*.dSYM*",
      "!",
      "-name",
      ".gitkeep",
    },
  })
end

-- Create command
vim.api.nvim_create_user_command("TaskFiles", find_task_files, {})

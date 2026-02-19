-- lus LSP configurations
vim.lsp.config.luals = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc" },
  settings = {
    Lua = {
      workspace = {
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
}

-- C/C++ Language Server configuration
vim.lsp.config.clangd = {
  cmd = { "clangd", "--background-index" },
  root_markers = { "compile_commands.json", "compile_flags.txt" },
  filetypes = { "c", "cpp" },
}

vim.lsp.config.nixd = {
  cmd = { "nixd" },
  root_markers = { "flake.nix", "default.nix", "shell.nix" },
  filetypes = { "nix" },
  settings = {
    nix = {
      format = {
        enable = true,
      },
    },
  },
}

vim.diagnostic.config({ virtual_lines = true })
vim.lsp.enable({ "luals", "nil_ls", "nixd", "pyright", "ruff", "bashls", "clangd" })

local binds = {
  { action = "<cmd>Telescope find_files<cr>", key = "<leader>f", mode = "n" },
  { action = "<cmd>Telescope live_grep<cr>", key = "<leader>t", mode = "n" },
  { action = ":BufferLineCycleNext<CR>", key = "<TAB>", mode = "n" },
  { action = ":BufferLineCyclePrev<CR>", key = "<S-TAB>", mode = "n" },
  { action = ":Bdelete<CR>", key = "X", mode = "n", options = { silent = true, desc = "Close buffer" } },
  { action = "<C-w>h", key = "<C-h>", mode = "n" },
  { action = "<C-w>j", key = "<C-j>", mode = "n" },
  { action = "<C-w>l", key = "<C-l>", mode = "n" },
  { action = "<C-w>k", key = "<C-k>", mode = "n" },
  { action = "<Cmd>NvimTreeToggle<CR>", key = "<leader>e", mode = "n", options = { silent = true, desc = "Toggle NvimTree" } },

  -- terminal navigation
  { action = "<C-\\><C-N><C-w>h", key = "<C-h>", mode = "t" },
  { action = "<C-\\><C-N><C-w>j", key = "<C-j>", mode = "t" },
  { action = "<C-\\><C-N><C-w>l", key = "<C-l>", mode = "t" },
  { action = "<C-\\><C-N><C-w>k", key = "<C-k>", mode = "t" },
  { action = "<C-\\><C-n>", key = "<Esc>", mode = "t", options = { silent = true } },

  -- LSP
  { action = "<cmd>lua vim.lsp.buf.declaration()<CR>", key = "gD", mode = "n" }, -- Go to definition
  { action = "<cmd>lua vim.lsp.buf.definition()<CR>", key = "gd", mode = "n" }, -- Hover documentation
  { action = "<cmd>lua vim.lsp.buf.hover()<CR>", key = "K", mode = "n" }, -- Go to implementation
  { action = "<cmd>lua vim.lsp.buf.implementation()<CR>", key = "gi", mode = "n" }, -- Signature help
  { action = "<cmd>lua vim.lsp.buf.signature_help()<CR>", key = "<C-k>", mode = "n" }, -- Rename symbol
  { action = "<cmd>lua vim.lsp.buf.rename()<CR>", key = "<leader>rn", mode = "n" }, -- Code actions
  { action = "<cmd>lua vim.lsp.buf.code_action()<CR>", key = "<leader>ca", mode = "n" }, -- List references
  { action = "<cmd>lua vim.lsp.buf.references()<CR>", key = "gr", mode = "n" }, -- Open diagnostic float window
  { action = "<cmd>lua vim.diagnostic.open_float()<CR>", key = "gl", mode = "n" }, -- Go to previous diagnostic
  { action = "<cmd>lua vim.diagnostic.goto_prev()<CR>", key = "[d", mode = "n" }, -- Go to next diagnostic
  { action = "<cmd>lua vim.diagnostic.goto_next()<CR>", key = "]d", mode = "n" },
}

for _, map in ipairs(binds) do
  vim.keymap.set(map.mode, map.key, map.action, map.options)
end

local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    c = { "clang-format" },
    cpp = { "clang-format" },
    h = { "clang-format" },
    hpp = { "clang-format" },
  },
  formatters = {
    ["clang-format"] = {
      command = "clang-format",
      args = { "--style=file" },
    },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})
-- Disable Lazy change-detection prompts (see NvChad discussion #2428)
pcall(function()
  local lazy_config = require("lazy.core.config")
  lazy_config.options.change_detection.notify = false
  lazy_config.options.change_detection.enabled = false
end)
if vim.env.CP_ENV then
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

end
require("nvchad.utils").reload()

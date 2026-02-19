local M = {}
M.base46 = {
  theme = "vscode_dark";
}

-- Override lazy.nvim defaults to stop change detection notifications
M.lazy_nvim = {
  change_detection = {
    enabled = false,
    notify = false,
  },
}

return M

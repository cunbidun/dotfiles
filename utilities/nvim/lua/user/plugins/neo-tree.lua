local M = {}

function M.setup()
  require("neo-tree").setup({
    close_if_last_window = true, -- close neo-tree if it's the last window
    enable_git_status = true,
    enable_diagnostics = true,
    default_component_configs = {
      name = {
        trailing_slash = true,
        use_git_status_colors = true,
      },
    },
    window = {
      mappings = {
        ["o"] = "open",
        ["s"] = "open_split",
        ["S"] = "open_vsplit",
      },
    },
    filesystem = {
      filtered_items = {
        visible = true, -- show hidden files by default
        hide_dotfiles = false,
        hide_gitignored = true,
      },
      follow_current_file = { enabled = true },
    },
  })
end
return M

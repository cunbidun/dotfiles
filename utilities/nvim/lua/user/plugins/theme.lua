return {
  {
    "vim-plugins/auto-dark-mode.nvim",
    opts = {},
  },
  {
    "vim-plugins/vscode.nvim",
    config = function()
      local json_decode = vim.json and vim.json.decode or vim.fn.json_decode
      local palette_path = vim.fn.expand("~/.local/state/colors.json")

      -- read Stylix JSON → return palette name (or nil on error)
      local function stylix_theme()
        if vim.fn.filereadable(palette_path) == 0 then
          return nil
        end
        local ok, data = pcall(json_decode, table.concat(vim.fn.readfile(palette_path), "\n"))
        return ok and data and data.theme or nil
      end

      local function apply_scheme(name)
        name = name or ""

        if name:lower():find("nord") then
          vim.cmd.colorscheme("nord")
        elseif name:lower():find("gruvbox") then
          require("gruvbox").setup({ contrast = "hard" })
          vim.cmd.colorscheme("gruvbox")
        else
          vim.cmd.colorscheme("vscode") -- default fallback
        end

        vim.g.colors_name = name:gsub("%s+", "_"):lower()
      end

      -- initial load ---------------------------------------------------------
      apply_scheme(stylix_theme())

      -- hot-reload whenever Stylix rewrites colors.json ----------------------
      local uv, watcher = vim.loop, vim.loop.new_fs_event()
      watcher:start(
        palette_path,
        {},
        vim.schedule_wrap(function()
          apply_scheme(stylix_theme())
        end)
      )
    end,
  },

  { "vim-plugins/gruvbox.nvim", lazy = true },
  { "vim-plugins/nord.nvim", lazy = true },
}

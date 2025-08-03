return {
  "vim-plugins/lualine.nvim",
  dependencies = {
    "vim-plugins/vscode.nvim",
    "vim-plugins/nvim-web-devicons",
  },
  opts = {
    options = { globalstatus = true },
    sections = {
      lualine_y = {}, -- make sure the section exists (can be empty)
    },
  },
  config = function(_, opts)
    -- Insert your custom venv component into lualine_y:
    table.insert(opts.sections.lualine_y, {
      function()
        local venv = vim.env.CONDA_DEFAULT_ENV or vim.env.VIRTUAL_ENV or "NO ENV"
        return " " .. venv
      end,
      cond = function()
        return vim.bo.filetype == "python"
      end,
    })
    -- Initialize lualine with the modified opts:
    require("lualine").setup(opts)
  end,
}

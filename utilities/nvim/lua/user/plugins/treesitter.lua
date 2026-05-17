return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local function start_ts(buf)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
        pcall(vim.treesitter.start, buf)
      end
    end

    -- Attach for files opened after startup.
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "FileType" }, {
      callback = function(args)
        start_ts(args.buf)
      end,
    })

    -- Attach for the file that triggered lazy-loading at startup.
    start_ts(vim.api.nvim_get_current_buf())
  end,
}

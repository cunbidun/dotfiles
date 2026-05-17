return {
  "brenton-leighton/multiple-cursors.nvim",
  opts = {},
  keys = {
    {
      "<D-M-j>",
      "<Cmd>MultipleCursorsAddDown<CR>",
      mode = { "n", "i", "x" },
      desc = "Add cursor and move down",
    },
    {
      "<D-M-k>",
      "<Cmd>MultipleCursorsAddUp<CR>",
      mode = { "n", "i", "x" },
      desc = "Add cursor and move up",
    },
    {
      "<D-M-Down>",
      "<Cmd>MultipleCursorsAddDown<CR>",
      mode = { "n", "i", "x" },
      desc = "Add cursor and move down",
    },
    {
      "<D-M-Up>",
      "<Cmd>MultipleCursorsAddUp<CR>",
      mode = { "n", "i", "x" },
      desc = "Add cursor and move up",
    },
    {
      "<D-M-CR>",
      "<Cmd>MultipleCursorsAddDelete<CR>",
      mode = "n",
      desc = "Add or remove cursor",
    },
    {
      "<leader>m",
      "<Cmd>MultipleCursorsAddVisualArea<CR>",
      mode = "x",
      desc = "Add cursors to visual area",
    },
  },
}

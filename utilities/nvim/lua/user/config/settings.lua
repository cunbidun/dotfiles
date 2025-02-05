local options = {
  autoindent = true,
  background = "light",
  clipboard = "unnamedplus",
  colorcolumn = "120",
  completeopt = { "menu", "menuone", "noselect" },
  cursorcolumn = false,
  cursorline = false,
  expandtab = true,
  fileencoding = "utf-8",
  foldexpr = "nvim_treesitter#foldexpr()",
  foldlevel = 99,
  foldmethod = "expr",
  hidden = true,
  ignorecase = true,
  inccommand = "split",
  incsearch = true,
  laststatus = 3,
  modeline = true,
  modelines = 100,
  mouse = "a",
  mousemodel = "extend",
  number = true,
  relativenumber = true,
  scrolloff = 8,
  shiftwidth = 2,
  signcolumn = "yes",
  smartcase = true,
  spell = false,
  splitbelow = true,
  splitright = true,
  swapfile = false,
  tabstop = 2,
  termguicolors = true,
  textwidth = 0,
  undofile = true,
  updatetime = 100,
  wrap = false,
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

local globals_options = { mapleader = " " }

for k, v in pairs(globals_options) do
  vim.g[k] = v
end

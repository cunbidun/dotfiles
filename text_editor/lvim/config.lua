reload("user.options")
reload("user.lvim_plugins.telescope")
reload("user.lvim_plugins.terminal")
reload("user.lvim_plugins.treesitter")
reload("user.lvim_plugins.which_key")
reload("user.lvim_plugins.easypick")
reload("user.lsp.clangd")

-- +------------------------------------------------------------+
-- | keymappings [view all the defaults by pressing <leader>Lk] |
-- +------------------------------------------------------------+
lvim.leader = "space"

-- bufferline {{{
lvim.keys.normal_mode["<TAB>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-TAB>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<S-x>"] = ":BufferKill<CR>"
lvim.keys.normal_mode["<C-\\>"] = ":ToggleTerm<CR>"
-- }}}

-- unmap a default keymapping {{{
lvim.keys.normal_mode["<S-l>"] = false
lvim.keys.normal_mode["<S-h>"] = false
lvim.keys.insert_mode["jk"] = false
lvim.keys.insert_mode["kj"] = false
lvim.keys.insert_mode["jj"] = false
-- }}}

-- lsp {{{
lvim.keys.normal_mode["<S-M-f>"] = "<cmd>lua vim.lsp.buf.formatting()<CR>"
-- }}}

-- +---------------+
-- | plugin config |
-- +---------------+
-- vsnip {{{
require("luasnip.loaders.from_vscode").load({ paths = { "~/dotfiles/text_editor/lvim/snippet/" } })
-- }}}

-- formatters {{{
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
  { exe = "black",   filetypes = { "python" } },
  { exe = "isort",   filetypes = { "python" } },
  { exe = "stylua",  filetypes = { "lua" } },
  { exe = "shfmt",   filetypes = { "sh" } },
  { exe = "rustfmt", filetypes = { "rust" } },
  { exe = "nixfmt",  filetypes = { "nixfmt" } },
})
-- }}}

-- linters {{{
local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
  { exe = "flake8", filetypes = { "python" } },
  {
    exe = "shellcheck",
    args = { "--severity", "warning" },
    filetypes = { "sh", "bash" },
  },
})
-- }}}

-- +--------------------+
-- | additional plugins |
-- +--------------------+
lvim.plugins = {
  { "shaunsingh/nord.nvim" },
  { "projekt0n/github-nvim-theme" },
  { "Mofiqul/vscode.nvim" },
  { "martinsione/darkplus.nvim" },
  { "moll/vim-bbye" },
  { "tpope/vim-surround" },
  { "axkirillov/easypick.nvim" },
  { "wakatime/vim-wakatime" },
}

-- +--------------------------------------------------------+
-- | autocommands (https://neovim.io/doc/user/autocmd.html) |
-- +--------------------------------------------------------+

-- general {{{
vim.api.nvim_create_autocmd("VimEnter", { pattern = { "*" }, command = ':silent exec "!kill -s SIGWINCH $PPID"' })
vim.api.nvim_create_autocmd("VimEnter", { pattern = { "*" }, command = "highlight SignColumn guibg=NONE" })
vim.api.nvim_create_autocmd("BufEnter", { pattern = { "*" }, command = "highlight BufferLineFill guibg=NONE" })
vim.api.nvim_create_autocmd("BufEnter", { pattern = { "*" }, command = "highlight ToggleTerm1SignColumn guibg=NONE" })
-- vim.api.nvim_create_autocmd("ColorScheme", { pattern = { "*" }, command = "highlight Normal guibg=NONE" })
vim.api.nvim_create_autocmd("ColorScheme", { pattern = { "*" }, command = "highlight VertSplit guifg=#4C566A" })

-- }}}

-- suckless {{{
vim.api.nvim_create_autocmd("VimEnter", {
  pattern = { "*.h" },
  callback = function()
    require("lvim.core.autocmds").disable_format_on_save()
  end,
})
-- }}}

-- +----+
-- | cp |
-- +----+
vim.cmd([[source $HOME/.config/lvim/cp.vim]])

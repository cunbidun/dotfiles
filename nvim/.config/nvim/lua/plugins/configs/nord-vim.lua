local M = {}

M.setup = function()
	vim.cmd('colorscheme nord')

	-- " no signcolumn and background
	vim.cmd [[au VimEnter * highlight Normal ctermbg=NONE guibg=NONE]]
	vim.cmd [[au VimEnter * highlight SignColumn guibg=NONE]]

	vim.cmd [[au VimEnter * highlight Nord0 guibg=#2E3440]]
	vim.cmd [[au VimEnter * highlight Nord9 guifg=#81A1C1 guibg=NONE]]

	vim.cmd [[au VimEnter * highlight Error guifg=#BF616A guibg=NONE]]

	vim.cmd [[au VimEnter * highlight QuickScopePrimary guifg=#2E3440 guibg=#88C0D0 gui=bold ctermfg=155 cterm=underline]]
	vim.cmd [[au VimEnter * highlight QuickScopeSecondary guifg=#2E3440 guibg=#EBCB8B gui=bold ctermfg=81 cterm=underline]]

	-- buffer bar
	vim.cmd [[au VimEnter * highlight BufferCurrent guifg=#88c0d0 guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferCurrentIndex guifg=#88c0d0 guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferCurrentSign guifg=#88c0d0 guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferCurrentIcon guifg=#A3BE8C guibg=NONE]]

	vim.cmd [[au VimEnter * highlight BufferVisible guifg=#4C566A guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferVisibleIndex guifg=#4C566A guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferVisibleIcon guifg=#4C566A guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferVisibleSign guifg=#4C566A guibg=NONE]]

	vim.cmd [[au VimEnter * highlight BufferInactive guifg=#4C566A guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferInactiveIndex guifg=#4C566A guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferInactiveIcon guifg=#4C566A guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferInactiveSign guifg=#4C566A guibg=NONE]]

	vim.cmd [[au VimEnter * highlight BufferCurrentMod guifg=#EBCB8B guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferInactiveMod guifg=#EBCB8B guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferVisibleMod guifg=#EBCB8B guibg=NONE]]

	vim.cmd [[au VimEnter * highlight BufferOffset guifg=NONE guibg=NONE]]
	vim.cmd [[au VimEnter * highlight BufferTabpages guifg=NONE guibg=NONE]]

	vim.cmd [[au VimEnter * highlight TabLine guifg=#4C566A guibg=#3B4252 ctermfg=254 ctermbg=238 gui=NONE cterm=NONE]]
	vim.cmd [[au VimEnter * highlight TabLineFill guifg=#4C566A guibg=#3B4252 ctermfg=254 ctermbg=NONE gui=NONE cterm=NONE]]
	vim.cmd [[au VimEnter * highlight TabLineSel guifg=#88c0d0 guibg=NONE ctermfg=110 ctermbg=240 gui=NONE cterm=NONE]]
end

return M
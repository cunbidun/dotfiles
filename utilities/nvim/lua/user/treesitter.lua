-- LazyVim wires treesitter highlighting and folding through its nvim-treesitter
-- spec, which is disabled in init.lua. Without it nothing calls
-- vim.treesitter.start(), so highlighting only happens by accident:
-- snacks.quickfile starts it once at startup for the file named on the command
-- line, and bails out afterwards (`vim.v.vim_did_enter == 1`). Buffers opened
-- later -- :edit, a picker, gd, a buffer switch -- silently fall back to the
-- legacy regex syntax, which has no notion of variables or types.
--
-- Folding has the same gap: it stays on LazyVim's `foldmethod=indent` default
-- unless the language server implements textDocument/foldingRange, so
-- clangd/lua_ls/vtsls buffers fold while python/nix ones effectively don't.

local group = vim.api.nvim_create_augroup("user_treesitter", { clear = true })

-- Highlighting. Errors when no parser exists for the filetype (including the
-- "bigfile" filetype snacks assigns to large files), which is the signal to
-- leave the buffer on its legacy syntax.
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	callback = function(ev)
		pcall(vim.treesitter.start, ev.buf)
	end,
})

local function has_lsp_folds(buf)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		local caps = client.server_capabilities
		if caps and caps.foldingRangeProvider then
			return true
		end
	end
	return false
end

local function has_parser(buf)
	local ok, parser = pcall(vim.treesitter.get_parser, buf, nil, { error = false })
	return ok and parser ~= nil
end

-- Prefer LSP folds where the server provides them, fall back to treesitter
-- folds otherwise. Done here rather than via LazyVim.set_default() because that
-- helper refuses to touch options last set by a non-$VIMRUNTIME script.
local function apply_folds(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local expr
	if has_lsp_folds(buf) then
		expr = "v:lua.vim.lsp.foldexpr()"
	elseif has_parser(buf) then
		expr = "v:lua.vim.treesitter.foldexpr()"
	else
		return
	end

	-- foldmethod/foldexpr are window-local, so set them on every window showing
	-- the buffer rather than assuming it is the current one: FileType can fire
	-- for buffers loaded in the background (session restore, :vsplit, quickfix).
	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		vim.api.nvim_set_option_value("foldmethod", "expr", { win = win, scope = "local" })
		vim.api.nvim_set_option_value("foldexpr", expr, { win = win, scope = "local" })
	end
end

-- FileType fires before any server attaches, so this sets treesitter folds
-- first; LspAttach then upgrades to LSP folds when the server offers them.
-- BufWinEnter covers buffers that had no window yet when FileType fired.
vim.api.nvim_create_autocmd({ "FileType", "LspAttach", "BufWinEnter" }, {
	group = group,
	callback = function(ev)
		vim.schedule(function()
			apply_folds(ev.buf)
		end)
	end,
})

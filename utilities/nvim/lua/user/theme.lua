local M = {}

local state_dir = vim.fn.expand("~/.local/state/theme-manager")
local theme_file = state_dir .. "/current-theme-name.txt"

local themes = {
	["default-dark"] = { background = "dark", colorscheme = "vscode" },
	["default-light"] = { background = "light", colorscheme = "vscode" },
	["catppuccin-dark"] = { background = "dark", colorscheme = "catppuccin", flavour = "mocha" },
	["catppuccin-light"] = { background = "light", colorscheme = "catppuccin", flavour = "latte" },
}

local last

local function load_plugin(name)
	pcall(function()
		require("lazy").load({ plugins = { name } })
	end)
end

function M.apply(force)
	local ok, lines = pcall(vim.fn.readfile, theme_file)
	local name = ok and lines[1] and vim.trim(lines[1])
	if not name or (name == last and not force) then
		return -- unreadable (e.g. mid-relink) or unchanged
	end
	last = name

	local theme = themes[name] or themes[vim.endswith(name, "-light") and "default-light" or "default-dark"]
	vim.o.background = theme.background
	load_plugin(theme.colorscheme)
	pcall(function()
		require("vscode").setup({ transparent = true })
	end)
	if theme.flavour then
		pcall(function()
			require("catppuccin").setup({ flavour = theme.flavour, transparent_background = true })
		end)
	end
	pcall(vim.cmd.colorscheme, theme.colorscheme)
end

function M.setup()
	M.apply(true)

	-- Watch the parent directory so atomic file replacement triggers one reload.
	local watcher = (vim.uv or vim.loop).new_fs_event()
	if not watcher or vim.fn.isdirectory(state_dir) == 0 then
		return
	end
	M._watcher = watcher

	local pending = false
	watcher:start(state_dir, {}, function(_, filename)
		if (filename == nil or filename == "current-theme-name.txt") and not pending then
			pending = true
			-- small delay lets the new symlink settle before we read it
			vim.defer_fn(function()
				pending = false
				M.apply()
			end, 100)
		end
	end)
end

return M

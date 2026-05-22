local M = {}

local function health_start(msg)
	if vim.health.start then
		vim.health.start(msg)
	else
		vim.fn["health#report_start"](msg)
	end
end

local function health_ok(msg)
	if vim.health.ok then
		vim.health.ok(msg)
	else
		vim.fn["health#report_ok"](msg)
	end
end

local function health_warn(msg, advice)
	if vim.health.warn then
		vim.health.warn(msg, advice)
	else
		vim.fn["health#report_warn"](msg, advice)
	end
end

local function health_info(msg)
	if vim.health.info then
		vim.health.info(msg)
	else
		vim.fn["health#report_info"](msg)
	end
end

local function normalize(path)
	return vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
end

local function in_plugin_root(dir, root)
	local normalized_dir = normalize(dir)
	return normalized_dir == root or vim.startswith(normalized_dir, root .. "/")
end

function M.check()
	health_start("Hermetic Lazy plugins")

	local ok, lazy = pcall(require, "lazy")
	if not ok then
		health_warn("lazy.nvim is not available", { "Check that lazy.nvim is present in ~/.local/share/vim-plugins." })
		return
	end

	local plugin_root = normalize(vim.fn.stdpath("data") .. "/vim-plugins")
	local plugins = lazy.plugins()
	local checked = 0
	local missing = {}
	local uv = vim.uv or vim.loop

	for _, plugin in ipairs(plugins) do
		local dir = plugin.dir
		local enabled = plugin.enabled ~= false

		if enabled and type(dir) == "string" and in_plugin_root(dir, plugin_root) then
			checked = checked + 1

			if not uv.fs_stat(dir) then
				table.insert(missing, {
					name = plugin.name or plugin[1] or dir,
					dir = dir,
					lazy = plugin.lazy,
				})
			end
		end
	end

	table.sort(missing, function(a, b)
		return a.name < b.name
	end)

	if #missing == 0 then
		health_ok(("All %d Lazy plugin directories under %s exist."):format(checked, plugin_root))
	else
		for _, plugin in ipairs(missing) do
			local lazy_state = plugin.lazy and "lazy=true" or "lazy=false"
			health_warn(
				("%s is declared by Lazy but missing on disk (%s): %s"):format(plugin.name, lazy_state, plugin.dir),
				{ ("Add the plugin to nvim-plugins in nix/home-manager/configs/nvim.nix with dir = %q."):format(plugin.name) }
			)
		end
	end

	health_info("Fast check: uses Lazy's resolved specs and fs_stat only; it does not load plugin modules.")
end

return M

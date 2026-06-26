local M = {}

local home = os.getenv("HOME")
local themeStateFile = home .. "/.local/state/theme-manager/current-theme-name.txt"
local activeThemeName = nil

local themes = {
	["catppuccin-dark"] = {
		background = "rgb(1E1E2E)",
		group_active = "rgb(89B4FA)",
		group_inactive = "rgb(313244)",
		group_text = "rgb(1E1E2E)",
		group_text_inactive = "rgb(CDD6F4)",
		border_active = "rgb(89B4FA)",
		border_inactive = "rgb(585B70)",
		border_locked_active = "rgb(A6E3A1)",
		shadow = "rgba(1E1E2E99)",
	},
	["catppuccin-light"] = {
		background = "rgb(EFF1F5)",
		group_active = "rgb(1E66F5)",
		group_inactive = "rgb(EFF1F5)",
		group_text = "rgb(EFF1F5)",
		group_text_inactive = "rgb(4C4F69)",
		border_active = "rgb(1E66F5)",
		border_inactive = "rgb(ACB0BE)",
		border_locked_active = "rgb(40A02B)",
		shadow = "rgba(EFF1F599)",
	},
	["default-dark"] = {
		background = "rgb(1C1C1E)",
		group_active = "rgb(0A84FF)",
		group_inactive = "rgb(2C2C2E)",
		group_text = "rgb(FFFFFF)",
		group_text_inactive = "rgb(FFFFFF)",
		border_active = "rgb(0A84FF)",
		border_inactive = "rgb(545458)",
		border_locked_active = "rgb(30D158)",
		shadow = "rgba(1C1C1E99)",
	},
	["default-light"] = {
		background = "rgb(FFFFFF)",
		group_active = "rgb(007AFF)",
		group_inactive = "rgb(F2F2F7)",
		group_text = "rgb(FFFFFF)",
		group_text_inactive = "rgb(000000)",
		border_active = "rgb(007AFF)",
		border_inactive = "rgb(3C3C43)",
		border_locked_active = "rgb(34C759)",
		shadow = "rgba(FFFFFF99)",
	},
}

local function read_theme_name()
	local file = io.open(themeStateFile, "r")
	if not file then
		return nil
	end
	local name = file:read("*l")
	file:close()
	return name
end

local function apply_colors(hl, colors)
	hl.config({
		misc = {
			background_color = colors.background,
		},
		general = {
			col = {
				active_border = colors.border_active,
				inactive_border = colors.border_inactive,
			},
		},
		group = {
			col = {
				border_active = colors.border_active,
				border_inactive = colors.border_inactive,
				border_locked_active = colors.border_locked_active,
			},
			groupbar = {
				col = {
					active = colors.group_active,
					inactive = colors.group_inactive,
				},
				text_color = colors.group_text,
				text_color_inactive = colors.group_text_inactive,
			},
		},
		decoration = {
			shadow = {
				color = colors.shadow,
			},
		},
	})
end

function M.colors()
	local name = assert(read_theme_name(), "missing Hyprland theme state")
	local colors = assert(themes[name], "unknown Hyprland theme: " .. name)
	activeThemeName = name
	return colors
end

function M.apply_if_changed(hl)
	local name = read_theme_name()
	if not name or name == "" or name == activeThemeName then
		return
	end
	local colors = themes[name]
	if not colors then
		return
	end
	apply_colors(hl, colors)
	activeThemeName = name
end

function M.watch(hl)
	_G.cunbidunThemeWatchGeneration = (_G.cunbidunThemeWatchGeneration or 0) + 1
	local generation = _G.cunbidunThemeWatchGeneration

	local function loop()
		hl.timer(function()
			if generation ~= _G.cunbidunThemeWatchGeneration then
				return
			end
			M.apply_if_changed(hl)
			loop()
		end, { timeout = 1000, type = "oneshot" })
	end

	loop()
end

return M

pcall(require, "luarocks.loader")

local battery_widget = require("awesome-wm-widgets.battery-widget.battery")
local volume_widget = require("awesome-wm-widgets.volume-widget.volume")
local temperature_widget = require("awesome-wm-widgets.temperature-widget.temperature")
local language_widget = require("awesome-wm-widgets.language-widget.language")

-- local doge_widget = require('awesome-wm-widgets.doge-widget.doge')
-- local mm_widget = require('awesome-wm-widgets.mm-widget.mm')

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
-- require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
	})
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure we don't go into an endless error loop
		if in_error then
			return
		end
		in_error = true
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err),
		})
		in_error = false
	end)
end
-- }}}

local theme = beautiful.init("~/.config/awesome/themes/nord/theme.lua")

-- utils function --
function useless_gaps_resize(thatmuch, s, t)
	local scr = s or awful.screen.focused()
	local tag = t or scr.selected_tag
	tag.gap = tag.gap + tonumber(thatmuch)
	awful.layout.arrange(scr)
end

-- This is used later as the default terminal and editor to run.
terminal = "alacritty"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
Modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
	awful.layout.suit.tile,
	awful.layout.suit.floating,
	awful.layout.suit.max,
	awful.layout.suit.spiral.dwindle,
}
-- }}}

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
Keyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
TextClock = wibox.widget({
	font = beautiful.font,
	widget = wibox.widget.textbox,
	markup = string.format("<span color='#81A1C1'> %s</span>", string.lower(os.date("%a %b %d, %H:%M:%S"))),
})

myclocktimer = timer({ timeout = 1 })
myclocktimer:connect_signal("timeout", function()
	TextClock:set_markup(
		string.format("<span color='#81A1C1'> %s</span>", string.lower(os.date("%a %b %d, %H:%M:%S")))
	)
end)
myclocktimer:start()

separator = wibox.widget.textbox(" │ ")

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),
	awful.button({ Modkey }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({ Modkey }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({}, 4, function(t)
		awful.tag.viewnext(t.screen)
	end),
	awful.button({}, 5, function(t)
		awful.tag.viewprev(t.screen)
	end)
)

local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal("request::activate", "tasklist", { raise = true })
		end
	end),
	awful.button({}, 3, function()
		awful.menu.client_list({ theme = { width = 250 } })
	end),
	awful.button({}, 4, function()
		awful.client.focus.byidx(1)
	end),
	awful.button({}, 5, function()
		awful.client.focus.byidx(-1)
	end)
)

local function set_wallpaper(s)
	-- Wallpaper
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		-- If wallpaper is a function, call it with the screen
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
	-- Wallpaper
	set_wallpaper(s)

	-- Each screen has its own tag table.
	local l = awful.layout.suit
	local layouts = { l.tile, l.tile, l.tile, l.tile, l.tile, l.tile, l.tile, l.tile, l.max }
	awful.tag({ "", "", "", "", "", "", "", "", "" }, s, layouts)

	-- Create an imagebox widget which will contain an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)

	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist({
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = taglist_buttons,
	})

	-- Create the wibox
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		-- visible = false
	})
	local right_widget = { layout = wibox.layout.fixed.horizontal }
	if s.index == 1 then
		right_widget = { -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			wibox.layout.margin(wibox.widget.systray(), 2, 2, 3, 3),
			separator, ------------------------------------------
			language_widget(),
			-- separator, ------------------------------------------
			-- doge_widget(),
			-- separator, ------------------------------------------
			-- mm_widget(),
			separator, ------------------------------------------
			temperature_widget(),
			separator, ------------------------------------------
			volume_widget(),
			separator, ------------------------------------------
			battery_widget(),
			separator, ------------------------------------------
			TextClock,
			wibox.widget.textbox("  "), -- padding
		}
	end

	-- Add widgets to the wibox
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		expand = "none",
		{ -- Left widgets
			wibox.widget.textbox("  "), -- pading
			layout = wibox.layout.fixed.horizontal,
			s.mytaglist,
		},
		s.mylayoutbox,
		right_widget,
	})
end)
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
	awful.key({ Modkey, "Mod1" }, "j", function()
		awful.client.incwfact(0.05)
	end),
	awful.key({ Modkey, "Mod1" }, "k", function()
		awful.client.incwfact(-0.05)
	end),
	awful.key({ Modkey, "Shift" }, "s", function()
		awful.spawn.with_shell("import png:- | xclip -selection clipboard -t image/png", false)
	end, {
		description = "take screen shot",
		group = "hotkeys",
	}),
	awful.key({ Modkey, "Shift" }, "n", function()
		awful.spawn.with_shell("nord_color_picker", false)
	end),
	awful.key({ Modkey, "Shift" }, "d", function()
		awful.spawn.with_shell("alacritty -e dotfiles_picker", false)
	end, {
		description = "edit config",
		group = "hotkeys",
	}),
	awful.key({ "Mod1" }, "Tab", function()
		awful.spawn.with_shell("rofi -show window", false)
	end),
	awful.key({ Modkey }, "space", language_widget.toggle, { description = "change language", group = "hotkeys" }),
	awful.key({}, "XF86AudioRaiseVolume", volume_widget.raise, { description = "volume up", group = "hotkeys" }),
	awful.key({}, "XF86AudioLowerVolume", volume_widget.lower, {
		description = "volume down",
		group = "hotkeys",
	}),
	awful.key({}, "XF86AudioMute", volume_widget.toggle, { description = "toggle mute", group = "hotkeys" }),
	awful.key(
		{ Modkey },
		"\\",
		naughty.destroy_all_notifications,
		{ description = "clear notifications", group = "awesome" }
	),
	awful.key({ Modkey }, "b", function()
		local s = awful.screen.focused()
		s.mywibox.visible = not s.mywibox.visible
	end, {
		description = "toggle wibox",
		group = "awesome",
	}),
	awful.key({ Modkey }, "s", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),

	awful.key({ Modkey }, "Left", awful.tag.viewprev, { description = "view previous", group = "tag" }),
	awful.key({ Modkey }, "Right", awful.tag.viewnext, {
		description = "view next",
		group = "tag",
	}),
	awful.key({ Modkey }, "Escape", awful.tag.history.restore, { description = "go back", group = "tag" }),

	awful.key({ Modkey }, "j", function()
		awful.client.focus.byidx(1)
	end, {
		description = "focus next by index",
		group = "client",
	}),
	awful.key({ Modkey }, "k", function()
		awful.client.focus.byidx(-1)
	end, {
		description = "focus previous by index",
		group = "client",
	}),
	awful.key({ Modkey, "Shift" }, "j", function()
		awful.client.swap.byidx(1)
	end, {
		description = "swap with next client by index",
		group = "client",
	}),
	awful.key({ Modkey, "Shift" }, "k", function()
		awful.client.swap.byidx(-1)
	end, {
		description = "swap with previous client by index",
		group = "client",
	}),
	awful.key({ Modkey }, ",", function()
		awful.screen.focus_relative(1)
	end, {
		description = "focus the next screen",
		group = "screen",
	}),
	awful.key({ Modkey }, ".", function()
		awful.screen.focus_relative(-1)
	end, {
		description = "focus the previous screen",
		group = "screen",
	}),
	awful.key({ Modkey }, "u", awful.client.urgent.jumpto, {
		description = "jump to urgent client",
		group = "client",
	}),
	awful.key({ Modkey }, "Tab", function()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end, {
		description = "go back",
		group = "client",
	}),
	awful.key({ Modkey }, "Return", function()
		awful.spawn(terminal)
	end, {
		description = "open a terminal",
		group = "launcher",
	}),
	awful.key({ Modkey, "Control" }, "r", awesome.restart, {
		description = "reload awesome",
		group = "awesome",
	}),
	awful.key({ Modkey, "Shift" }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),

	awful.key({ Modkey }, "l", function()
		awful.tag.incmwfact(0.05)
	end, {
		description = "increase master width factor",
		group = "layout",
	}),
	awful.key({ Modkey }, "h", function()
		awful.tag.incmwfact(-0.05)
	end, {
		description = "decrease master width factor",
		group = "layout",
	}),
	awful.key({ Modkey, "Shift" }, "h", function()
		awful.tag.incnmaster(1, nil, true)
	end, {
		description = "increase the number of master clients",
		group = "layout",
	}),

	awful.key({ Modkey, "Shift" }, "l", function()
		awful.tag.incnmaster(-1, nil, true)
	end, {
		description = "decrease the number of master clients",
		group = "layout",
	}),

	awful.key({ Modkey, "Control" }, "h", function()
		awful.tag.incncol(1, nil, true)
	end, {
		description = "increase the number of columns",
		group = "layout",
	}),

	awful.key({ Modkey, "Control" }, "l", function()
		awful.tag.incncol(-1, nil, true)
	end, {
		description = "decrease the number of columns",
		group = "layout",
	}),
	awful.key({ Modkey }, "i", function()
		awful.layout.inc(1)
	end, { description = "select next", group = "layout" }),
	awful.key({ Modkey, "Shift" }, "i", function()
		awful.layout.inc(-1)
	end, {
		description = "select previous",
		group = "layout",
	}),
	awful.key({ Modkey, "Control" }, "n", function()
		local c = awful.client.restore()
		-- Focus restored client
		if c then
			c:emit_signal("request::activate", "key.unminimize", { raise = true })
		end
	end, {
		description = "restore minimized",
		group = "client",
	}),
	awful.key({ Modkey }, "p", function()
		menubar.show()
	end, {
		description = "show the menubar",
		group = "launcher",
	})
)

clientkeys = gears.table.join(
	awful.key({ Modkey }, "f", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, {
		description = "toggle fullscreen",
		group = "client",
	}),
	awful.key({ Modkey, "Shift" }, "c", function(c)
		c:kill()
	end, { description = "close", group = "client" }),
	awful.key(
		{ Modkey, "Control" },
		"space",
		awful.client.floating.toggle,
		{ description = "toggle floating", group = "client" }
	),
	awful.key({ Modkey, "Control" }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, {
		description = "move to master",
		group = "client",
	}),
	awful.key({ Modkey, "Shift" }, ".", function(c)
		c:move_to_screen()
	end, {
		description = "move to screen",
		group = "client",
	}),
	awful.key({ Modkey }, "t", function(c)
		c.ontop = not c.ontop
	end, {
		description = "toggle keep on top",
		group = "client",
	}),
	awful.key({ Modkey }, "n", function(c)
		-- The client currently has the input focus, so it cannot be
		-- minimized, since minimized clients can't have the focus.
		c.minimized = true
	end, {
		description = "minimize",
		group = "client",
	}),
	awful.key({ Modkey }, "m", function(c)
		c.maximized = not c.maximized
		c:raise()
	end, {
		description = "(un)maximize",
		group = "client",
	}),
	awful.key({ Modkey, "Control" }, "m", function(c)
		c.maximized_vertical = not c.maximized_vertical
		c:raise()
	end, {
		description = "(un)maximize vertically",
		group = "client",
	}),
	awful.key({ Modkey, "Shift" }, "m", function(c)
		c.maximized_horizontal = not c.maximized_horizontal
		c:raise()
	end, {
		description = "(un)maximize horizontally",
		group = "client",
	})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = gears.table.join(
		globalkeys,
		awful.key({ Modkey }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, {
			description = "view tag #" .. i,
			group = "tag",
		}),
		awful.key({ Modkey, "Control" }, "#" .. i + 9, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end, {
			description = "toggle tag #" .. i,
			group = "tag",
		}),
		awful.key({ Modkey, "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, {
			description = "move focused client to tag #" .. i,
			group = "tag",
		}),
		awful.key({ Modkey, "Control", "Shift" }, "#" .. i + 9, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end, {
			description = "toggle focused client on tag #" .. i,
			group = "tag",
		})
	)
end

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
	end),
	awful.button({ Modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.move(c)
	end),
	awful.button({ Modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.resize(c)
	end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
		},
	}, ------------------------------ pop-up ------------------------------
	{ rule_any = { role = { "pop-up" } }, properties = { floating = true } },

	------------------------------ to titlebar rule ------------------------------
	{ rule_any = { type = { "normal", "dialog" } }, properties = { titlebars_enabled = false } },

	------------------------------ discord rule ------------------------------
	{ rule = { class = "discord" }, properties = { tag = "9:workspace" } },

	------------------------------ slack rule ------------------------------
	{ rule = { instance = "slack" }, properties = { tag = "9:workspace" } },

	------------------------------ chromium ------------------------------
	{ rule = { instance = "chromium" }, properties = { tag = "3:web" } },

	------------------------------ zoom ------------------------------
	{ rule = { instance = "zoom" }, properties = { tag = "8:meeting" } },

	------------------------------ steam ------------------------------
	{ rule = { instance = "Steam" }, properties = { tag = "7:gaming" } },
}
-- }}}

-- {{{ Signals
-- Focus urgent clients automatically
client.connect_signal("property::urgent", function(c)
	c.minimized = false
	c:jump_to()
end)

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
	-- Set the windows at the slave,
	-- i.e. put it at the end of others instead of setting it master.
	if not awesome.startup then
		awful.client.setslave(c)
	end

	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
	end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
	-- buttons for the titlebar
	local buttons = gears.table.join(
		awful.button({}, 1, function()
			c:emit_signal("request::activate", "titlebar", { raise = true })
			awful.mouse.client.move(c)
		end),
		awful.button({}, 3, function()
			c:emit_signal("request::activate", "titlebar", { raise = true })
			awful.mouse.client.resize(c)
		end)
	)

	awful.titlebar(c):setup({
		{ -- Left
			awful.titlebar.widget.iconwidget(c),
			buttons = buttons,
			layout = wibox.layout.fixed.horizontal,
		},
		{ -- Middle
			{ -- Title
				align = "center",
				widget = awful.titlebar.widget.titlewidget(c),
			},
			buttons = buttons,
			layout = wibox.layout.flex.horizontal,
		},
		{ -- Right
			awful.titlebar.widget.floatingbutton(c),
			awful.titlebar.widget.maximizedbutton(c),
			awful.titlebar.widget.stickybutton(c),
			awful.titlebar.widget.ontopbutton(c),
			awful.titlebar.widget.closebutton(c),
			layout = wibox.layout.fixed.horizontal(),
		},
		layout = wibox.layout.align.horizontal,
	})
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)

-- Auto start applications
awful.spawn.with_shell("xset r rate 200 30")
awful.spawn.with_shell("feh --bg-fill --randomize ~/.wallpapers/nord/*")
-- awful.spawn.with_shell('picom --experimental-backends')
-- awful.spawn.with_shell('nm-applet')
awful.spawn.with_shell("ibus-daemon -drx")
awful.spawn.with_shell("cd ~/competitive_programming/cc/ && npm start")

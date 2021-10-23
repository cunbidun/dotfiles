local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local theme = {}

-- color
theme.nord0 = "#2E3440"
theme.nord1 = "#3B4252"
theme.nord2 = "#434C5E"
theme.nord3 = "#4C566A"
theme.nord4 = "#D8DEE9"
theme.nord5 = "#E5E9F0"
theme.nord6 = "#ECEFF4"
theme.nord7 = "#8FBCBB"
theme.nord8 = "#88C0D0"
theme.nord9 = "#81A1C1"
theme.nord10 = "#5E81AC"
theme.nord11 = "#BF616A"
theme.nord12 = "#D08770"
theme.nord13 = "#EBCB8B"
theme.nord14 = "#A3BE8C"
theme.nord15 = "#B48EAD"

theme.font = "SauceCodePro Nerd Font Mono 11"
theme.transparent = "#00000000"

theme.bg_normal = theme.nord0

theme.wibar_bg = theme.nord1
theme.bg_focus = theme.bg_normal
theme.bg_urgent = theme.bg_normal
theme.bg_minimize = theme.bg_normal
theme.bg_systray = theme.wibar_bg

theme.fg_normal = theme.nord4
theme.fg_focus = theme.fg_normal
theme.fg_urgent = theme.fg_normal
theme.fg_minimize = theme.fg_normal

theme.useless_gap = dpi(10)
theme.border_width = dpi(3)
theme.border_normal = theme.nord3
theme.border_marked = theme.nord11
theme.border_focus = theme.nord8
theme.accent = theme.nord8

theme.tasklist_bg_focus = theme.nord0
theme.tasklist_icon_size = dpi(5)
theme.tasklist_plain_task_name = true

theme.taglist_spacing = dpi(5)

theme.menu_height = dpi(15)
theme.menu_width = dpi(100)

theme.background = theme.nord0

theme.icon_theme = nil

theme.taglist_bg_focus = theme.nord1
theme.taglist_fg_focus = theme.nord13
theme.taglist_bg_occupied = theme.nord1
theme.taglist_fg_occupied = theme.nord14
theme.taglist_bg_empty = theme.nord1
theme.taglist_fg_empty = theme.nord9
theme.taglist_bg_urgent = theme.nord1
theme.taglist_fg_urgent = theme.nord11

-- hotkey
theme.hotkeys_border_color = theme.nord8
theme.hotkeys_modifiers_fg = theme.nord3

-- notification theme
theme.notification_width = 250
theme.notification_icon_size = 50
theme.notification_margin = 20
theme.notification_border_color = theme.nord8

theme.flash_focus_start_opacity = 0.6 -- the starting opacity
theme.flash_focus_step = 0.01 -- the step of animation

-- window switcher
theme.flash_focus_start_opacity = 1 -- the starting opacity
theme.flash_focus_step = 0.01 -- the step of animation
theme.window_switcher_widget_bg = "#4C566A" -- The bg color of the widget
theme.window_switcher_widget_border_width = 3 -- The border width of the widget
theme.window_switcher_widget_border_radius = 0 -- The border radius of the widget
theme.window_switcher_widget_border_color = theme.border_focus -- The border color of the widget
theme.window_switcher_clients_spacing = 20 -- The space between each client item
theme.window_switcher_client_icon_horizontal_spacing = 5 -- The space between client icon and text
theme.window_switcher_client_width = 150 -- The width of one client widget
theme.window_switcher_client_height = 250 -- The height of one client widget
theme.window_switcher_client_margins = 10 -- The margin between the content and the border of the widget
theme.window_switcher_thumbnail_margins = 10 -- The margin between one client thumbnail and the rest of the widget
theme.thumbnail_scale = false -- If set to true, the thumbnails fit policy will be set to "fit" instead of "auto"
theme.window_switcher_name_margins = 10 -- The margin of one clients title to the rest of the widget
theme.window_switcher_name_valign = "center" -- How to vertically align one clients title
theme.window_switcher_name_forced_width = 200 -- The width of one title
theme.window_switcher_name_font = theme.font -- The font of all titles
theme.window_switcher_name_normal_color = theme.nord6 -- The color of one title if the client is unfocused
theme.window_switcher_name_focus_color = theme.nord8 -- The color of one title if the client is focused
theme.window_switcher_icon_valign = "center" -- How to vertically align the one icon
theme.window_switcher_icon_width = 40 -- The width of one icon

-- window swallowing
theme.dont_swallow_classname_list = { "firefox", "Gimp" } -- list of class names that should not be swallowed
theme.dont_swallow_filter_activated = true -- whether the filter above should be active

-- For tabbed only
theme.tabbed_spawn_in_tab = false -- whether a new client should spawn into the focused tabbing container

-- For tabbar in general
theme.tabbar_ontop = false
theme.tabbar_radius = 0 -- border radius of the tabbar
theme.tabbar_style = "default" -- style of the tabbar ("default", "boxes" or "modern")
theme.tabbar_font = theme.font -- font of the tabbar
theme.tabbar_size = 30 -- size of the tabbar
theme.tabbar_position = "top" -- position of the tabbar
theme.tabbar_bg_normal = theme.nord2 -- background color of the focused client on the tabbar
theme.tabbar_fg_normal = theme.nord6 -- foreground color of the focused client on the tabbar
theme.tabbar_bg_focus = theme.nord3 -- background color of unfocused clients on the tabbar
theme.tabbar_fg_focus = theme.nord8 -- foreground color of unfocused clients on the tabbar
theme.tabbar_bg_focus_inactive = nil -- background color of the focused client on the tabbar when inactive
theme.tabbar_fg_focus_inactive = nil -- foreground color of the focused client on the tabbar when inactive
theme.tabbar_bg_normal_inactive = nil -- background color of unfocused clients on the tabbar when inactive
theme.tabbar_fg_normal_inactive = nil -- foreground color of unfocused clients on the tabbar when inactive
theme.tabbar_disable = false -- disable the tab bar entirely

return theme

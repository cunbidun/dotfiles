local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local theme_path = "~/.config/awesome/themes/nord/"

local theme = {}

-- color
theme.nord0  = "#2E3440"
theme.nord1  = "#3B4252"
theme.nord2  = "#434C5E"
theme.nord3  = "#4C566A"
theme.nord4  = "#D8DEE9"
theme.nord5  = "#E5E9F0"
theme.nord6  = "#ECEFF4"
theme.nord7  = "#8FBCBB"
theme.nord8  = "#88C0D0"
theme.nord9  = "#81A1C1"
theme.nord10 = "#5E81AC"
theme.nord11 = "#BF616A"
theme.nord12 = "#D08770"
theme.nord13 = "#EBCB8B"
theme.nord14 = "#A3BE8C"
theme.nord15 = "#B48EAD"

theme.font          = "Source Code Pro 10"
theme.transparent   = "#00000000"

theme.bg_normal     = theme.nord0

theme.wibar_bg      = theme.nord1
theme.bg_focus      = theme.bg_normal
theme.bg_urgent     = theme.bg_normal
theme.bg_minimize   = theme.bg_normal
theme.bg_systray    = theme.wibar_bg

theme.fg_normal     = theme.nord4
theme.fg_focus      = theme.fg_normal
theme.fg_urgent     = theme.fg_normal
theme.fg_minimize   = theme.fg_normal

theme.useless_gap   = dpi(8)
theme.border_width  = dpi(2)
theme.border_normal = theme.nord5
theme.border_marked = theme.nord11
theme.border_focus  = theme.nord8
theme.accent        = theme.nord8

theme.tasklist_bg_focus         = theme.nord0
theme.tasklist_icon_size        = dpi(5)
theme.tasklist_plain_task_name  = true

theme.taglist_spacing = dpi(5)

theme.menu_height = dpi(15)
theme.menu_width  = dpi(100)

theme.wallpaper   = theme_path.."wallpaper2.png"
theme.background  = theme.nord0

theme.icon_theme = nil

theme.taglist_bg_focus    = theme.nord1
theme.taglist_fg_focus    = theme.nord13
theme.taglist_bg_occupied = theme.nord1
theme.taglist_fg_occupied = theme.nord14
theme.taglist_bg_empty    = theme.nord1
theme.taglist_fg_empty    = theme.nord9
theme.taglist_bg_urgent   = theme.nord1
theme.taglist_fg_urgent   = theme.nord11

-- hotkey
theme.hotkeys_border_color = theme.nord8
theme.hotkeys_modifiers_fg = theme.nord3

-- notification theme
theme.notification_width = 250
theme.notification_icon_size = 50
theme.notification_margin = 20
-- theme.notification_border_width =
theme.notification_border_color = theme.nord8

return theme


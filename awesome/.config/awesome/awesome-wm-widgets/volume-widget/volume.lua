local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local beautiful = require('beautiful')

local GET_VOLUME_CMD = 'amixer sget Master'

local level_widget = {} wibox.widget {
    font = beautiful.font,
    widget = wibox.widget.textbox
}

local volume = {device = '',  notification = nil, delta = 5}

function volume:toggle()
    volume:_cmd('amixer ' .. volume.device .. ' sset Master toggle')
end
function volume:raise()
    volume:_cmd('amixer ' .. volume.device .. ' sset Master ' .. tostring(volume.delta) .. '%+')
end
function volume:lower()
    volume:_cmd('amixer ' .. volume.device .. ' sset Master ' .. tostring(volume.delta) .. '%-')
end

local function parse_output(stdout)
    local level = string.match(stdout, "(%d?%d?%d)%%")
    if stdout:find("%[off%]") then
        level_widget.markup = string.format("<span color='#BF616A'>%d%%</span>", level)
        return level.."% <span color=\"#BF616A\">mute</span>"
    end
    level = tonumber(string.format("% 3d", level))
    level_widget.markup = string.format("<span color='#81A1C1'>%d%%</span>", level)
    return level.."%"
end

local function update_graphic(widget, stdout, _, _, _)
    local txt = parse_output(stdout)
    naughty.replace_text(volume.notification, "volume change", txt)
end

local function notif(msg, keep)
    naughty.destroy(volume.notification)

    volume.notification = naughty.notify {
        fg = "#81A1C1",
        timeout = keep and 0 or 2, 
        hover_timeout = 0.5,
        width = 140,
        margin = 15,
        screen = mouse.screen,
        border_width = 2,
    }
end

local function worker(args)
    local args = args or {}

    volume.device = '-D pulse'
    volume.delta = args.delta or 5
    GET_VOLUME_CMD = 'amixer -D pulse sget Master'

    local text_widget = wibox.widget {
        font = beautiful.font,
        widget = wibox.widget.textbox,
        markup = "<span color='#81A1C1'>vol: </span>",
    }
    level_widget = wibox.widget {
        font = beautiful.font,
        widget = wibox.widget.textbox
    }
    volume.widget = wibox.widget {
        text_widget, 
        level_widget,
        layout = wibox.layout.fixed.horizontal,
    }
    function volume:_cmd(cmd)
        notif("")
        spawn.easy_async(cmd, function(stdout, stderr, exitreason, exitcode)
            update_graphic(volume.widget, stdout, stderr, exitreason, exitcode)
        end)
    end

    spawn.easy_async(GET_VOLUME_CMD, function(stdout, stderr, exitreason, exitcode)
        parse_output(stdout)
    end)

    return volume.widget
end

return setmetatable(volume, { __call = function(_, ...) return worker(...) end })

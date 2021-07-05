local wibox = require('wibox')
local watch = require('awful.widget.watch')
local beautiful = require('beautiful')
local json = require("json")
local temperature_widget = {}

local function worker(args)
    local args = args or {}

    local timeout = args.timeout or 30

    local text_widget = wibox.widget {
        font = beautiful.font,
        widget = wibox.widget.textbox,
        markup = "<span color='#81A1C1'>doge: </span>",
    }

    local level_widget = wibox.widget {
        font = beautiful.font,
        widget = wibox.widget.textbox
    }

    temperature_widget = wibox.widget {
        text_widget,
        level_widget,
        layout = wibox.layout.fixed.horizontal,
    }

    watch('bash -c "curl -s https://sochain.com//api/v2/get_price/DOGE/USD"', timeout, 
    function(_, stdout)
        local result = json.decode(stdout)
        -- level_widget.markup = string.format("<span color='#81A1C1'>%s</span>", result.data.prices[0].price)
        if result.data.prices[1].exchange == "binance" then 
            level_widget.markup = string.format("<span color='#81A1C1'>%s</span>", result.data.prices[1].price)
        else 
            level_widget.markup = string.format("<span color='#81A1C1'>%s</span>", result.data.prices[2].price)
        end
    end)

    return temperature_widget
end

return setmetatable(temperature_widget, { __call = function(_, ...) return worker(...) end })

local wibox = require('wibox')
local watch = require('awful.widget.watch')
local beautiful = require('beautiful')

local temperature = wibox.widget.textbox()
temperature.font = beautiful.font

watch('bash -c "sensors | awk \'/Core 0/ {print substr($3, 2) }\'"', 30, function(_, stdout)
    temperature.text = stdout
end)

return temperature
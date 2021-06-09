local watch = require('awful.widget.watch')
local wibox = require('wibox')
local beautiful = require('beautiful')

local battery_widget = {}
local function worker(args)
  local args = args or {}

  local timeout = args.timeout or 10

  local text_widget = wibox.widget {
    font = beautiful.font,
    widget = wibox.widget.textbox,
    markup = '<span color=\'#81A1C1\'>bat: </span>'
  }
  local level_widget = wibox.widget {font = beautiful.font, widget = wibox.widget.textbox}
  battery_widget = wibox.widget {text_widget, level_widget, layout = wibox.layout.fixed.horizontal}

  watch('acpi -i', timeout, function(widget, stdout, stderr, exitreason, exitcode)
    local battery_info = {}
    local capacities = {}
    for s in stdout:gmatch('[^\r\n]+') do
      local status, charge_str, time = string.match(s, '.+: (%a+), (%d?%d?%d)%%,?(.*)')
      if status ~= nil then
        table.insert(battery_info, {status = status, charge = tonumber(charge_str)})
      else
        local cap_str = string.match(s, '.+:.+last full capacity (%d+)')
        table.insert(capacities, tonumber(cap_str))
      end
    end

    local capacity = 0
    for i, cap in ipairs(capacities) do capacity = capacity + cap end

    local charge = 0
    local status
    for i, batt in ipairs(battery_info) do
      if batt.charge >= charge then status = batt.status end
      charge = charge + batt.charge * capacities[i]
    end
    charge = charge / capacity

    if status == 'Discharging' then
      level_widget.markup = string.format('<span color=\'#EBCB8B\'>%d%%</span>', charge)
    else
      level_widget.markup = string.format('<span color=\'#81A1C1\'>%d%%</span>', charge)
    end
  end)
  return battery_widget
end

return setmetatable(battery_widget, {
  __call = function(_, ...)
    return worker(...)
  end
})

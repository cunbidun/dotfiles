local wibox = require('wibox')
local beautiful = require('beautiful')
local spawn = require('awful.spawn')
local awful = require('awful')

local current_language = {}
local language = {}

function language:toggle()
  spawn.easy_async('ibus engine', function(stdout, _, _, _)
    local lang = string.gsub(stdout, '%s+', '')
    awful.spawn.with_shell('set_language', false)
    if lang == 'xkb:us::eng' then current_language.markup = '<span color=\'#EBCB8B\'> vi</span>' end
    if lang == 'Bamboo' then current_language.markup = '<span color=\'#81A1C1\'> en</span>' end
  end)
end

local function worker(_)
  current_language = wibox.widget {font = beautiful.font, widget = wibox.widget.textbox}
  language.widget = wibox.widget {current_language, layout = wibox.layout.fixed.horizontal}
  spawn.easy_async('ibus engine', function()
    awful.spawn.with_shell('ibus engine xkb:us:eng', false)
    current_language.markup = '<span color=\'#81A1C1\'> en</span>'
  end)
  return language.widget
end

return setmetatable(language, {
  __call = function(_, ...)
    return worker(...)
  end
})

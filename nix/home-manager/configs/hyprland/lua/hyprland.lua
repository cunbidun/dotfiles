local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
package.path = configHome .. "/hypr/?.lua;" .. package.path

local nix = require("nix")
local mainMod = "SUPER"

hl.plugin.load(nix.plugins.hyprfocus)

local function exec(cmd)
  return hl.dsp.exec_cmd(cmd)
end

local function exec_and_reset(cmd)
  return function()
    hl.dispatch(exec(cmd))
    hl.dispatch(hl.dsp.submap("reset"))
  end
end

local function dispatch_and_reset(dispatcher)
  return function()
    hl.dispatch(dispatcher)
    hl.dispatch(hl.dsp.submap("reset"))
  end
end

hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})

hl.config({
  ecosystem = {
    no_update_news = true,
  },

  misc = {
    enable_swallow = true,
    swallow_exception_regex = "wev|^(.*[Yy]azi.*)$|ranger|^(.*nvim.*)$|^(.*Competitive Programming.*)$",
    swallow_regex = "kitty",
    disable_hyprland_logo = true,
    focus_on_activate = true,
    background_color = nix.colors.background,
  },

  debug = {
    disable_logs = true,
  },

  group = {
    groupbar = {
      font_family = "SFMono Nerd Font",
      font_size = 13,
      indicator_height = 0,
      height = 21,
      rounding = 0,
      gradients = true,
      col = {
        active = nix.colors.group_active,
        inactive = nix.colors.group_inactive,
      },
      text_color = nix.colors.group_text,
      text_color_inactive = nix.colors.group_text_inactive,
    },
    col = {
      border_active = nix.colors.border_active,
      border_inactive = nix.colors.border_inactive,
      border_locked_active = nix.colors.border_locked_active,
    },
  },

  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    repeat_rate = 50,
    repeat_delay = 200,
    -- Keep focus following the mouse as before.
    follow_mouse = 1,
    touchpad = {
      natural_scroll = true,
    },
    sensitivity = 0,
  },

  general = {
    gaps_in = 5,
    gaps_out = 5,
    border_size = 2,
    layout = "dwindle",
    col = {
      active_border = nix.colors.border_active,
      inactive_border = nix.colors.border_inactive,
    },
  },

  decoration = {
    rounding = 8,
    shadow = {
      color = nix.colors.shadow,
    },
    blur = {
      enabled = true,
      size = 10,
      passes = 3,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    preserve_split = true,
    force_split = 2,
  },

  master = {
    mfact = 0.5,
  },

  plugin = {
    hyprfocus = {
      enabled = true,
      animate_floating = true,
      animate_workspacechange = false,
      focus_animation = "flash",
      exclude_class = "^jetbrains-",
      flash = {
        flash_opacity = 0.8,
        in_bezier = "realsmooth",
        in_speed = 0.25,
        out_bezier = "realsmooth",
        out_speed = 1.5,
      },
    },
  },
})

hl.curve("smooth", { type = "bezier", points = { {0.22, 1}, {0.36, 1} } })
hl.curve("easeOutCubic", { type = "bezier", points = { {0.33, 1}, {0.68, 1} } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "smooth", style = "popin 75%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 8, bezier = "easeOutCubic", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "smooth" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "smooth" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "smooth", style = "slidefade 10%" })

hl.on("hyprland.start", function()
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("env > ${XDG_RUNTIME_DIR}/hypr/hyprland-runtime-env")
  hl.exec_cmd("uwsm finalize")
end)

local windowRules = {
  { match = { class = "^(dota2)$" }, decorate = false },
  { match = { class = "^(dota2)$" }, no_blur = true },
  { match = { class = "^(dota2)$" }, no_shadow = true },
  { match = { class = "^(dota2)$" }, workspace = "8 silent" },
  { match = { class = "^(cs2)$" }, workspace = "8 silent" },
  { match = { class = "^(cs2)$" }, decorate = false },
  { match = { class = "^(cs2)$" }, no_blur = true },
  { match = { class = "^(cs2)$" }, no_shadow = true },
  { match = { title = "^(Spotify Premium)$" }, float = true },
  { match = { class = "^([Ss]ignal)$" }, float = true },
  { match = { class = "^(obsidian)$" }, float = true },
  { match = { title = "^(Scratchpad)$" }, float = true },
  { match = { title = "^(Open File)$" }, float = true },
  { match = { class = "^(ueberzugpp.*)$" }, no_anim = true },
  { match = { title = "^(.*ueberzugpp.*)$" }, no_anim = true },
  { match = { class = "^(vicinae.*)$" }, stay_focused = true },
  { match = { title = "^(Vicinae Launcher)$" }, stay_focused = true },
  { match = { title = "^(Vicinae Launcher)$" }, decorate = false },
  { match = { class = "^(Code)$", title = "(.*dotfiles.*Visual Studio Code.*)" }, workspace = "1 silent" },
  { match = { class = "^([Ss]team)$" }, workspace = "8 silent" },
  { match = { class = "^(chrome-.*messenger.*)$" }, float = true },
  { match = { class = "^(chrome-.*zalo.*)$" }, float = true },
  { match = { class = "^(chrome-.*chatgpt.*)$" }, float = true },
  { match = { class = "^(.*1password.*)$" }, float = true },
  { match = { class = "^(.*1password.*)$" }, pin = true },
  { match = { class = "^(.*1password.*)$" }, center = true },
  { match = { class = "^(.*1password.*)$" }, size = "50% 50%" },
  { match = { title = "^(FileChooser)$" }, float = true },
  { match = { title = "^(FileChooser)$" }, pin = true },
  { match = { title = "^(FileExplorer)$" }, float = true },
  { match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true },
  { match = { class = "^(xdg-desktop-portal-gtk)$" }, pin = true },
  { match = { title = "^(Bluetooth Devices)$" }, float = true },
  { match = { title = "^(__waybar_popup)$" }, size = "50% 50%" },
  { match = { title = "^(__waybar_popup)$" }, float = true },
  { match = { title = "^(__waybar_popup)$" }, pin = true },
  { match = { class = "^(spicy)$" }, float = true },
  { match = { class = "^(spicy)$" }, decorate = false },
  { match = { class = "^(spicy)$" }, no_blur = true },
}

for _, rule in ipairs(windowRules) do
  hl.window_rule(rule)
end

local agsPopupLayerNamespaces = "^(dashboardmenu|audiomenu|mediamenu|networkmenu|bluetoothmenu|notificationsmenu|calendarmenu|energymenu|powerdropdownmenu|sshforwardingmenu|verification|notifications-window|osd.*)$"

local layerRules = {
  { match = { namespace = agsPopupLayerNamespaces }, blur = true },
  { match = { namespace = agsPopupLayerNamespaces }, ignore_alpha = 0.2 },
}

for _, rule in ipairs(layerRules) do
  hl.layer_rule(rule)
end

hl.bind("XF86AudioRaiseVolume", exec(nix.commands.increase_volume), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", exec(nix.commands.decrease_volume), { locked = true, repeating = true })
hl.bind("XF86AudioMute", exec(nix.commands.toggle_volume), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", exec("brightnessctl set +5%"), { locked = true, repeating = true })

hl.bind(mainMod .. " + Return", exec("$TERMINAL"))
hl.bind(mainMod .. " + P", exec("vicinae dmenu-apps"))
hl.bind("ALT + space", exec("vicinae toggle"))
hl.bind(mainMod .. " + M", exec(nix.commands.hyprland_mode))
hl.bind(mainMod .. " + SHIFT + S", exec("slurp | grim -g - - | wl-copy -t image/png"))
hl.bind(mainMod .. " + CTRL + SHIFT + S", exec(nix.commands.screenshot_copy_upload))
hl.bind(mainMod .. " + slash", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close())
hl.bind(mainMod .. " + backslash", exec("makoctl dismiss -a"))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.swap({ direction = "d" }))

hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.swap({ direction = "d" }))

local projectKeys = {
  ["1"] = 1,
  ["2"] = 2,
  ["3"] = 3,
  ["4"] = 4,
  ["5"] = 5,
  a = 6,
  q = 7,
  g = 8,
  ["9"] = 9,
}

for key, workspace in pairs(projectKeys) do
  hl.bind(mainMod .. " + " .. key, exec(nix.commands.wsctl .. " project " .. workspace))
  hl.bind(mainMod .. " + SHIFT + " .. key, exec(nix.commands.wsctl .. " project-move " .. workspace))
end

hl.bind(mainMod .. " + t", hl.dsp.submap("group"))
hl.define_submap("group", function()
  hl.bind("t", dispatch_and_reset(hl.dsp.group.toggle()))
  hl.bind("o", dispatch_and_reset(hl.dsp.window.move({ out_of_group = true })))
  hl.bind("h", dispatch_and_reset(hl.dsp.window.move({ into_group = "l" })))
  hl.bind("j", dispatch_and_reset(hl.dsp.window.move({ into_group = "d" })))
  hl.bind("k", dispatch_and_reset(hl.dsp.window.move({ into_group = "u" })))
  hl.bind("l", dispatch_and_reset(hl.dsp.window.move({ into_group = "r" })))
  hl.bind("n", hl.dsp.group.next())
  hl.bind("p", hl.dsp.group.prev())
  hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + mouse:274", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + mouse:274", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + SHIFT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
  hl.bind("l", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
  hl.bind("h", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
  hl.bind("k", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
  hl.bind("j", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
  hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
  hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
  hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
  hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))
  hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.submap("property"))
hl.define_submap("property", function()
  hl.bind("f", hl.dsp.window.fullscreen())
  hl.bind("s", hl.dsp.window.pin())
  hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + S", function()
  hl.timer(function()
    hl.dispatch(hl.dsp.submap("reset"))
  end, { timeout = 1000, type = "oneshot" })
  hl.dispatch(hl.dsp.submap("scratchpad"))
end)
hl.define_submap("scratchpad", function()
  hl.bind("m", exec_and_reset("pypr toggle spotify"))
  hl.bind("s", exec_and_reset("pypr toggle signal"))
  hl.bind("c", exec_and_reset("pypr toggle chatgpt"))
  hl.bind("z", exec_and_reset("pypr toggle zalo"))
  hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + W", function()
  hl.timer(function()
    hl.dispatch(hl.dsp.submap("reset"))
  end, { timeout = 1000, type = "oneshot" })
  hl.dispatch(hl.dsp.submap("ws"))
end)

hl.define_submap("ws", function()
  for i = 1, 5 do
    hl.bind(tostring(i), exec_and_reset(nix.commands.wsctl .. " goto " .. i))
    hl.bind("SHIFT + " .. i, exec_and_reset(nix.commands.wsctl .. " move " .. i))
  end
  hl.bind("w", exec_and_reset(nix.commands.wsctl .. " main"))
  hl.bind("SHIFT + w", exec_and_reset(nix.commands.wsctl .. " main-move"))
  hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind(mainMod .. " + Grave", exec("pypr toggle term"))
hl.bind(mainMod .. " + c", exec("pypr toggle messenger"))
hl.bind(mainMod .. " + n", exec("pypr toggle obsidian"))
hl.bind(mainMod .. " + e", exec("pypr toggle file"))

local function place_tree(ctx, targets, area, i, side)
  if i > #targets then
    return
  end

  if i == #targets then
    targets[i]:place(area)
    return
  end

  if side == "v" then
    targets[i]:place(ctx.split("top", area, nil, 0.5))
    place_tree(ctx, targets, ctx.split("bottom", area, nil, 0.5), i + 1, "h")
  else
    targets[i]:place(ctx.split("left", area, nil, 0.5))
    place_tree(ctx, targets, ctx.split("right", area, nil, 0.5), i + 1, "v")
  end
end

hl.layout.register("editor_side_tree", {
  recalculate = function(ctx)
    local n = #ctx.targets
    if n == 0 then
      return
    end

    -- First window takes full screen.
    if n == 1 then
      ctx.targets[1]:place(ctx.area)
      return
    end

    -- Main/editor is the first window, kept on the right 2/3.
    local support_area = ctx.split("left", ctx.area, nil, 1.0 / 3.0)
    local main_area    = ctx.split("right", ctx.area, nil, 2.0 / 3.0)

    ctx.targets[1]:place(main_area)

    -- Remaining windows tile inside the left 1/3.
    place_tree(ctx, ctx.targets, support_area, 2, "v")
  end,
})


hl.workspace_rule({ workspace = "1", layout = "lua:editor_side_tree" })
hl.workspace_rule({ workspace = "7", layout = "scrolling" })
hl.bind(mainMod .. " + p", hl.dsp.layout("promote"))
hl.workspace_rule({ workspace = "9", layout = "lua:editor_side_tree" })

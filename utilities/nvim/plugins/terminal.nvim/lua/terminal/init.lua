local M = {}

local MODULE = "terminal"

local groups = {}
local active = 0

M._internal = false
M._restoring = false
M._fallback_target = nil

local WINBAR = "%{%v:lua.UserTerminalArea_winbar()%}"

local function setup_highlights()
  vim.api.nvim_set_hl(0, "TermGroupActive", { link = "TabLineSel" })
  vim.api.nvim_set_hl(0, "TermGroupInactive", { link = "TabLine" })
  vim.api.nvim_set_hl(0, "TermGroupFill", { link = "TabLineFill" })
end

local function is_terminal_buf(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.api.nvim_buf_is_loaded(buf)
    and vim.bo[buf].buftype == "terminal"
end

local function job_alive(buf)
  if not is_terminal_buf(buf) then
    return false
  end

  local job = vim.b[buf].terminal_job_id
  return job ~= nil and vim.fn.jobwait({ job }, 0)[1] == -1
end

local function visible_terminal_wins()
  local terms = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok and is_terminal_buf(buf) then
      table.insert(terms, win)
    end
  end

  table.sort(terms, function(a, b)
    local pa = vim.api.nvim_win_get_position(a)
    local pb = vim.api.nvim_win_get_position(b)

    if pa[1] ~= pb[1] then
      return pa[1] < pb[1]
    end

    return pa[2] < pb[2]
  end)

  return terms
end

local function live_terminal_wins()
  local out = {}

  for _, win in ipairs(visible_terminal_wins()) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok and job_alive(buf) then
      table.insert(out, win)
    end
  end

  return out
end

local function win_box(wins)
  local top, left = math.huge, math.huge
  local bottom, right = 0, 0

  for _, win in ipairs(wins) do
    local pos = vim.api.nvim_win_get_position(win)

    top = math.min(top, pos[1])
    left = math.min(left, pos[2])
    bottom = math.max(bottom, pos[1] + vim.api.nvim_win_get_height(win))
    right = math.max(right, pos[2] + vim.api.nvim_win_get_width(win))
  end

  return {
    height = bottom - top,
    width = right - left,
  }
end

local function prune_groups()
  local kept = {}
  local new_active

  for i, g in ipairs(groups) do
    g.bufs = vim.tbl_filter(function(buf)
      return is_terminal_buf(buf)
    end, g.bufs)

    if #g.bufs > 0 then
      table.insert(kept, g)

      if i == active then
        new_active = #kept
      end
    end
  end

  groups = kept
  active = new_active or math.min(active, #groups)

  if active < 1 then
    active = #groups > 0 and 1 or 0
  end
end

local function adopt_orphans()
  local tracked = {}

  for _, g in ipairs(groups) do
    for _, buf in ipairs(g.bufs) do
      tracked[buf] = true
    end
  end

  local shown = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok then
      shown[buf] = true
    end
  end

  local orphans = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if job_alive(buf) and not tracked[buf] and not shown[buf] then
      table.insert(orphans, buf)
    end
  end

  table.sort(orphans)

  if #orphans > 0 then
    table.insert(groups, {
      bufs = orphans,
      position = "bottom",
    })

    active = #groups
  end
end

local function sync_active()
  local wins = live_terminal_wins()

  if #wins == 0 then
    return
  end

  if active == 0 then
    table.insert(groups, {
      bufs = {},
      position = "bottom",
    })

    active = #groups
  end

  local bufs = {}

  for _, win in ipairs(wins) do
    table.insert(bufs, vim.api.nvim_win_get_buf(win))
  end

  local box = win_box(wins)
  local position = box.width >= box.height * 2 and "bottom" or "right"

  groups[active] = {
    bufs = bufs,
    position = position,
    size = position == "bottom" and box.height or box.width,
  }
end

function M.winbar()
  if #groups == 0 then
    return ""
  end

  local parts = {
    "%#TermGroupFill# term ",
  }

  for i, g in ipairs(groups) do
    local hl = i == active and "%#TermGroupActive#" or "%#TermGroupInactive#"

    local label
    if #g.bufs > 1 then
      label = (" %d·%d "):format(i, #g.bufs)
    else
      label = (" %d "):format(i)
    end

    local click = ("%%%d@v:lua.UserTerminalArea_on_click@"):format(i)

    parts[#parts + 1] = click .. hl .. label .. "%T%#TermGroupFill# "
  end

  return table.concat(parts)
end

function M.on_click(minwid)
  M.goto_group(tonumber(minwid))
end

local function apply_winbar()
  local wins = visible_terminal_wins()
  for i, win in ipairs(wins) do
    pcall(function()
      vim.wo[win].winbar = i == 1 and WINBAR or ""
    end)
  end
end

local function save_focus()
  if active > 0 and groups[active] then
    local buf = vim.api.nvim_get_current_buf()
    if is_terminal_buf(buf) then
      groups[active].focus = buf
    end
  end
end

local function snacks()
  local ok, s = pcall(require, "snacks")
  if ok then
    return s
  end

  return rawget(_G, "Snacks")
end

local function open_terminal(win_opts)
  local s = snacks()

  if s and s.terminal and s.terminal.open then
    s.terminal.open({ vim.o.shell }, {
      win = win_opts or { position = "current" },
    })
  else
    if vim.bo.buftype ~= "" then
      vim.cmd("enew")
    end

    vim.fn.termopen(vim.o.shell)
    vim.cmd("startinsert")
  end

  local buf = vim.api.nvim_get_current_buf()

  if is_terminal_buf(buf) then
    vim.bo[buf].bufhidden = "hide"
  end

  return buf
end

local function hide_visible()
  local wins = visible_terminal_wins()

  if #wins == 0 then
    return false
  end

  save_focus()
  sync_active()

  for _, win in ipairs(wins) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok and is_terminal_buf(buf) then
      vim.bo[buf].bufhidden = "hide"
    end
  end

  M._internal = true

  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, false)
    end
  end

  M._internal = false

  return true
end

local function open_fresh()
  local buf = open_terminal({ position = "bottom" })

  if is_terminal_buf(buf) and groups[active] then
    groups[active].bufs = { buf }
  end

  apply_winbar()
end

local function show_group(idx)
  prune_groups()

  if #groups == 0 then
    adopt_orphans()
    prune_groups()
  end

  if #groups == 0 then
    table.insert(groups, {
      bufs = {},
      position = "bottom",
    })

    active = 1
    open_fresh()
    return 0
  end

  active = math.max(1, math.min(idx, #groups))

  local g = groups[active]

  if #g.bufs == 0 then
    open_fresh()
    return 0
  end

  local split = g.position == "right" and "vsplit" or "split"

  if g.size then
    vim.cmd("botright " .. g.size .. split)
  else
    vim.cmd("botright " .. split)
  end

  local target = g.focus and is_terminal_buf(g.focus) and g.focus or g.bufs[1]
  vim.api.nvim_win_set_buf(0, target)

  local inner = g.position == "right" and "split" or "vsplit"

  for i = 2, #g.bufs do
    vim.cmd(inner)
    vim.api.nvim_win_set_buf(0, g.bufs[i])
  end

  apply_winbar()

  return #g.bufs
end

function M.toggle()
  if hide_visible() then
    return
  end

  show_group(active ~= 0 and active or 1)
end

function M.split()
  local wins = visible_terminal_wins()

  if #wins == 0 then
    if show_group(active ~= 0 and active or 1) == 0 then
      return
    end

    wins = visible_terminal_wins()

    if #wins == 0 then
      return
    end
  end

  vim.api.nvim_set_current_win(wins[1])

  local w = vim.api.nvim_win_get_width(0)
  local h = vim.api.nvim_win_get_height(0)

  if w > h * 2 then
    vim.cmd("vsplit")
  else
    vim.cmd("split")
  end

  open_terminal({ position = "current" })

  sync_active()
  apply_winbar()
end

function M.new_group()
  hide_visible()

  table.insert(groups, {
    bufs = {},
    position = "bottom",
  })

  active = #groups

  open_fresh()
  apply_winbar()
end

local function switch(dir)
  prune_groups()

  if #groups == 0 then
    show_group(1)
    return
  end

  save_focus()
  hide_visible()

  active = ((active - 1 + dir) % #groups) + 1

  show_group(active)
  M.status()
end

function M.next_group()
  switch(1)
end

function M.prev_group()
  switch(-1)
end

function M.goto_group(idx)
  prune_groups()

  if #groups == 0 then
    show_group(1)
    return
  end

  idx = math.max(1, math.min(tonumber(idx) or active, #groups))

  if idx == active and #visible_terminal_wins() > 0 then
    return
  end

  save_focus()
  hide_visible()

  active = idx

  show_group(active)
  M.status()
end

function M.status()
  prune_groups()

  if #groups == 0 then
    vim.notify("No terminal groups", vim.log.levels.INFO, {
      title = "Terminal",
    })

    return
  end

  local g = groups[active]

  vim.notify(
    ("Terminal group %d/%d (%d pane%s)"):format(
      active,
      #groups,
      #g.bufs,
      #g.bufs == 1 and "" or "s"
    ),
    vim.log.levels.INFO,
    {
      title = "Terminal",
    }
  )
end

function M._state()
  local snapshot = {}

  for i, g in ipairs(groups) do
    snapshot[i] = {
      bufs = vim.deepcopy(g.bufs),
      position = g.position,
      size = g.size,
    }
  end

  return {
    groups = snapshot,
    active = active,
  }
end

M._visible_terminal_wins = visible_terminal_wins

local function restore_loop(attempts, stable)
  prune_groups()

  if #groups == 0 then
    M._restoring = false
    return
  end

  if #live_terminal_wins() > 0 then
    sync_active()
    apply_winbar()

    stable = stable + 1

    if stable >= 2 then
      M._restoring = false
      return
    end
  else
    local target = M._fallback_target or 1
    active = target >= 1 and math.min(target, #groups) or #groups

    M._internal = true
    pcall(show_group, active)
    M._internal = false

    stable = 0
  end

  if attempts < 8 then
    vim.defer_fn(function()
      restore_loop(attempts + 1, stable)
    end, 70)
  else
    M._restoring = false
  end
end

local function drop_buf_from_groups(buf)
  local owned = false

  for _, g in ipairs(groups) do
    local before = #g.bufs

    g.bufs = vim.tbl_filter(function(b)
      return b ~= buf
    end, g.bufs)

    if #g.bufs ~= before then
      owned = true
    end
  end

  return owned
end

function M.setup()
  setup_highlights()

  _G.UserTerminalArea_winbar = function()
    return require(MODULE).winbar()
  end

  _G.UserTerminalArea_on_click = function(minwid, clicks, button, mods)
    return require(MODULE).on_click(minwid, clicks, button, mods)
  end

  local augroup = vim.api.nvim_create_augroup("UserTerminalArea", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = setup_highlights,
  })

  vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    callback = function(args)
      local buf = args.buf

      local owned = drop_buf_from_groups(buf)

      if not owned then
        return
      end

      prune_groups()
      apply_winbar()

      if M._restoring then
        return
      end

      M._restoring = true

      vim.defer_fn(function()
        prune_groups()

        if #live_terminal_wins() > 0 then
          sync_active()
          apply_winbar()
          M._restoring = false
          return
        end

        if #groups == 0 then
          M._restoring = false
          return
        end

        M._fallback_target = math.min(active, #groups)
        restore_loop(1, 0)
      end, 30)
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    callback = function(args)
      if M._internal then
        return
      end

      local win = tonumber(args.match)

      if not win then
        return
      end

      local ok, buf = pcall(vim.api.nvim_win_get_buf, win)

      if not ok then
        return
      end

      local tracked = false

      for _, g in ipairs(groups) do
        for _, b in ipairs(g.bufs) do
          if b == buf then
            tracked = true
            break
          end
        end

        if tracked then
          break
        end
      end

      if not tracked then
        return
      end

      if #groups < 2 then
        return
      end

      if M._restoring then
        return
      end

      M._fallback_target = active - 1
      M._restoring = true

      vim.defer_fn(function()
        if M._internal then
          M._restoring = false
          return
        end

        restore_loop(1, 0)
      end, 30)
    end,
  })
end

return M

local M = {}
local api = vim.api

local buf_name = api.nvim_buf_get_name
local cur_buf = api.nvim_get_current_buf
local get_opt = api.nvim_get_option_value
local get_hl = api.nvim_get_hl
local strep = string.rep

function M.txt(str, hl)
  return "%#Tb" .. hl .. "#" .. (str or "")
end

function M.btn(str, hl, func, arg)
  str = hl and M.txt(str, hl) or str
  arg = arg or ""
  return "%" .. arg .. "@UserTb" .. func .. "@" .. str .. "%X"
end

local function filename(str)
  return str:match("([^/\\]+)[/\\]*$")
end

local function new_hl(group1, group2)
  local ok_fg, fg_hl = pcall(get_hl, 0, { name = group1, link = false })
  local ok_bg, bg_hl = pcall(get_hl, 0, { name = "Tb" .. group2, link = false })

  local fg = ok_fg and fg_hl.fg or nil
  local bg = ok_bg and bg_hl.bg or nil

  api.nvim_set_hl(0, group1 .. group2, { fg = fg, bg = bg })
  return "%#" .. group1 .. group2 .. "#"
end

local function gen_unique_name(name, index)
  for i2, nr2 in ipairs(vim.t.bufs or {}) do
    local filepath = filename(buf_name(nr2))
    if index ~= i2 and filepath == name then
      return vim.fn.fnamemodify(buf_name(vim.t.bufs[index]), ":h:t") .. "/" .. name
    end
  end
end

function M.style_buf(nr, i, w)
  local icon = " "
  local is_curbuf = cur_buf() == nr
  local tb_hl_name = "BufO" .. (is_curbuf and "n" or "ff")
  local icon_hl = new_hl("DevIconDefault", tb_hl_name)

  local name = filename(buf_name(nr))
  name = name and (gen_unique_name(name, i) or name) or " No Name "

  if name ~= " No Name " then
    local ok, devicons = pcall(require, "nvim-web-devicons")

    if ok then
      local devicon, devicon_hl = devicons.get_icon(name)
      if devicon then
        icon = " " .. devicon .. " "
        icon_hl = new_hl(devicon_hl, tb_hl_name)
      end
    end
  end

  local pad = math.floor((w - #name - 5) / 2)
  pad = pad <= 0 and 1 or pad

  local maxname_len = w - 5
  name = string.sub(name, 1, maxname_len - 2) .. (#name > maxname_len and ".." or "")
  name = M.txt(name, tb_hl_name)

  name = strep(" ", pad - 1) .. (icon_hl .. icon .. name) .. strep(" ", pad - 1)

  local close_btn = M.btn(" x ", nil, "KillBuf", nr)
  name = M.btn(name, nil, "GoToBuf", nr)

  local modified = get_opt("modified", { buf = nr })

  if is_curbuf then
    close_btn = modified and M.txt(" * ", "BufOnModified") or M.txt(close_btn, "BufOnClose")
  else
    close_btn = modified and M.txt(" * ", "BufOffModified") or M.txt(close_btn, "BufOffClose")
  end

  return M.txt(name .. close_btn, "BufO" .. (is_curbuf and "n" or "ff"))
end

return M

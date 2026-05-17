local api = vim.api
local fn = vim.fn

local tabufline = require("user.tabufline")
local utils = require("user.tabufline.utils")

local btn = utils.btn
local strep = string.rep
local style_buf = utils.style_buf
local txt = utils.txt
local opts = tabufline.opts

local M = {}

vim.cmd([[
  function! UserTbGoToBuf(bufnr,b,c,d)
    call luaeval('require("user.tabufline").goto_buf(_A)', a:bufnr)
  endfunction
]])

vim.cmd([[
  function! UserTbKillBuf(bufnr,b,c,d)
    call luaeval('require("user.tabufline").close_buffer(_A)', a:bufnr)
  endfunction
]])

vim.cmd("function! UserTbNewTab(a,b,c,d) \n tabnew \n endfunction")
vim.cmd("function! UserTbGotoTab(tabnr,b,c,d) \n execute a:tabnr .. 'tabnext' \n endfunction")
vim.cmd("function! UserTbCloseAllBufs(a,b,c,d) \n lua require('user.tabufline').close_all_buffers() \n endfunction")
vim.cmd("function! UserTbToggleTabs(a,b,c,d) \n let g:UserTbTabsToggled = !g:UserTbTabsToggled | redrawtabline \n endfunction")

local function get_nvim_tree_width()
  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].filetype == "NvimTree" then
      return api.nvim_win_get_width(win)
    end
  end

  return 0
end

local function available_space()
  local str = ""

  for _, key in ipairs(opts.order) do
    if key ~= "buffers" then
      str = str .. M[key]()
    end
  end

  local modules = api.nvim_eval_statusline(str, { use_tabline = true })
  return vim.o.columns - modules.width
end

function M.treeOffset()
  local w = get_nvim_tree_width()
  return w == 0 and "" or "%#NvimTreeNormal#" .. strep(" ", w) .. "%#NvimTreeWinSeparator#" .. "|"
end

function M.buffers()
  local buffers = {}
  local has_current = false

  vim.t.bufs = vim.tbl_filter(api.nvim_buf_is_valid, vim.t.bufs or {})

  for i, nr in ipairs(vim.t.bufs) do
    if ((#buffers + 1) * opts.bufwidth) > available_space() then
      if has_current then
        break
      end

      table.remove(buffers, 1)
    end

    has_current = api.nvim_get_current_buf() == nr or has_current
    table.insert(buffers, style_buf(nr, i, opts.bufwidth))
  end

  return table.concat(buffers) .. txt("%=", "Fill")
end

vim.g.UserTbTabsToggled = vim.g.UserTbTabsToggled or 0

function M.tabs()
  local result, tabs = "", fn.tabpagenr("$")

  if tabs > 1 then
    for nr = 1, tabs do
      local tab_hl = "TabO" .. (nr == fn.tabpagenr() and "n" or "ff")
      result = result .. btn(" " .. nr .. " ", tab_hl, "GotoTab", nr)
    end

    local new_tab_btn = btn(" + ", "TabNewBtn", "NewTab")
    local tabs_btn = btn(" TABS ", "TabTitle", "ToggleTabs")
    local small_btn = btn(" ... ", "TabTitle", "ToggleTabs")

    return vim.g.UserTbTabsToggled == 1 and small_btn or new_tab_btn .. tabs_btn .. result
  end

  return ""
end

function M.btns()
  return btn(" x ", "CloseAllBufsBtn", "CloseAllBufs")
end

return function()
  opts = require("user.tabufline").opts

  if opts.modules then
    for key, value in pairs(opts.modules) do
      M[key] = value
    end
  end

  local result = {}
  for _, module in ipairs(opts.order) do
    table.insert(result, M[module]())
  end

  return table.concat(result)
end

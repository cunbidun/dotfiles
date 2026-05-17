local M = {}
local api = vim.api

local cur_buf = api.nvim_get_current_buf
local get_opt = api.nvim_get_option_value
local set_buf = api.nvim_set_current_buf

M.opts = require("user.tabufline.config")

local function buf_index(bufnr)
  for i, value in ipairs(vim.t.bufs or {}) do
    if value == bufnr then
      return i
    end
  end
end

local function listed_buffers()
  return vim.tbl_filter(function(buf)
    return api.nvim_buf_is_valid(buf) and get_opt("buflisted", { buf = buf })
  end, api.nvim_list_bufs())
end

local function ensure_tab_buffers()
  vim.t.bufs = vim.t.bufs or listed_buffers()
end

local function enable_tabline()
  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.require('user.tabufline.modules')()"
end

local function setup_highlights()
  local normal = api.nvim_get_hl(0, { name = "Normal", link = false })
  local visual = api.nvim_get_hl(0, { name = "Visual", link = false })
  local comment = api.nvim_get_hl(0, { name = "Comment", link = false })
  local error = api.nvim_get_hl(0, { name = "DiagnosticError", link = false })

  local fg = normal.fg or 0xd4d4d4
  local bg = normal.bg or 0x1e1e1e
  local active_bg = visual.bg or 0x3a3d41
  local inactive_fg = comment.fg or 0x808080
  local accent = error.fg or 0xf44747

  local groups = {
    TbFill = { fg = fg, bg = bg },
    TbBufOn = { fg = fg, bg = active_bg, bold = true },
    TbBufOff = { fg = inactive_fg, bg = bg },
    TbBufOnClose = { fg = inactive_fg, bg = active_bg },
    TbBufOffClose = { fg = inactive_fg, bg = bg },
    TbBufOnModified = { fg = accent, bg = active_bg },
    TbBufOffModified = { fg = accent, bg = bg },
    TbTabOn = { fg = fg, bg = active_bg, bold = true },
    TbTabOff = { fg = inactive_fg, bg = bg },
    TbTabNewBtn = { fg = fg, bg = bg },
    TbTabTitle = { fg = inactive_fg, bg = bg },
    TbCloseAllBufsBtn = { fg = accent, bg = bg },
  }

  for name, value in pairs(groups) do
    api.nvim_set_hl(0, name, value)
  end
end

local function setup_tracking()
  ensure_tab_buffers()

  local group = api.nvim_create_augroup("UserTabufline", { clear = true })

  api.nvim_create_autocmd({ "BufAdd", "BufEnter", "TabNew" }, {
    group = group,
    callback = function(args)
      local bufs = vim.t.bufs
      local is_curbuf = cur_buf() == args.buf

      if bufs == nil then
        bufs = is_curbuf and {} or { args.buf }
      elseif
        not vim.tbl_contains(bufs, args.buf)
        and (args.event == "BufEnter" or not is_curbuf or get_opt("buflisted", { buf = args.buf }))
        and api.nvim_buf_is_valid(args.buf)
        and get_opt("buflisted", { buf = args.buf })
      then
        table.insert(bufs, args.buf)
      end

      if args.event == "BufAdd" and bufs[1] and api.nvim_buf_is_valid(bufs[1]) then
        if #api.nvim_buf_get_name(bufs[1]) == 0 and not get_opt("modified", { buf = bufs[1] }) then
          table.remove(bufs, 1)
        end
      end

      vim.t.bufs = bufs
    end,
  })

  api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(args)
      for _, tab in ipairs(api.nvim_list_tabpages()) do
        local bufs = vim.t[tab].bufs
        if bufs then
          for i, bufnr in ipairs(bufs) do
            if bufnr == args.buf then
              table.remove(bufs, i)
              vim.t[tab].bufs = bufs
              break
            end
          end
        end
      end
    end,
  })

  api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "qf" },
    callback = function()
      vim.opt_local.buflisted = false
    end,
  })
end

local function setup_lazyload()
  if not M.opts.lazyload then
    enable_tabline()
    return
  end

  local group = api.nvim_create_augroup("UserTabuflineLazyLoad", { clear = true })

  api.nvim_create_autocmd({ "BufNew", "BufNewFile", "BufRead", "TabEnter", "TermOpen" }, {
    pattern = "*",
    group = group,
    callback = function()
      if #vim.fn.getbufinfo({ buflisted = 1 }) >= 2 or #api.nvim_list_tabpages() >= 2 then
        enable_tabline()
        api.nvim_del_augroup_by_name("UserTabuflineLazyLoad")
      end
    end,
  })
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

  if not M.opts.enabled then
    return
  end

  setup_tracking()
  setup_highlights()
  setup_lazyload()

  api.nvim_create_autocmd("ColorScheme", {
    group = api.nvim_create_augroup("UserTabuflineHighlights", { clear = true }),
    callback = setup_highlights,
  })
end

function M.next()
  ensure_tab_buffers()

  local bufs = vim.t.bufs
  local curbuf_index = buf_index(cur_buf())

  if not bufs or #bufs == 0 then
    return
  end

  if not curbuf_index then
    set_buf(bufs[1])
    return
  end

  set_buf((curbuf_index == #bufs and bufs[1]) or bufs[curbuf_index + 1])
end

function M.prev()
  ensure_tab_buffers()

  local bufs = vim.t.bufs
  local curbuf_index = buf_index(cur_buf())

  if not bufs or #bufs == 0 then
    return
  end

  if not curbuf_index then
    set_buf(bufs[1])
    return
  end

  set_buf((curbuf_index == 1 and bufs[#bufs]) or bufs[curbuf_index - 1])
end

function M.close_buffer(bufnr)
  ensure_tab_buffers()
  bufnr = bufnr or cur_buf()

  if vim.bo[bufnr].buftype == "terminal" then
    vim.cmd(vim.bo[bufnr].buflisted and "setlocal nobuflisted | enew" or "hide")
  else
    local curbuf_index = buf_index(bufnr)
    local bufhidden = vim.bo[bufnr].bufhidden

    if api.nvim_win_get_config(0).zindex then
      vim.cmd("bwipeout")
      return
    elseif curbuf_index and #vim.t.bufs > 1 then
      local new_buf_index = curbuf_index == #vim.t.bufs and -1 or 1
      vim.cmd("buffer " .. vim.t.bufs[curbuf_index + new_buf_index])
    elseif not vim.bo[bufnr].buflisted then
      local tmpbufnr = vim.t.bufs[1]
      if tmpbufnr then
        local winid = vim.fn.bufwinid(tmpbufnr)
        if winid ~= -1 then
          api.nvim_set_current_win(winid)
        end
        api.nvim_set_current_buf(tmpbufnr)
      end
      vim.cmd("bwipeout " .. bufnr)
      return
    else
      vim.cmd("enew")
    end

    if bufhidden ~= "delete" then
      vim.cmd("confirm bdelete " .. bufnr)
    end
  end

  vim.cmd("redrawtabline")
end

function M.close_all_buffers(include_cur_buf)
  ensure_tab_buffers()

  local bufs = vim.deepcopy(vim.t.bufs or {})

  if include_cur_buf ~= nil and not include_cur_buf then
    table.remove(bufs, buf_index(cur_buf()))
  end

  for _, buf in ipairs(bufs) do
    if api.nvim_buf_is_valid(buf) then
      M.close_buffer(buf)
    end
  end
end

function M.move_buf(n)
  ensure_tab_buffers()

  local bufs = vim.t.bufs

  for i, bufnr in ipairs(bufs) do
    if bufnr == cur_buf() then
      if (n < 0 and i == 1) or (n > 0 and i == #bufs) then
        bufs[1], bufs[#bufs] = bufs[#bufs], bufs[1]
      else
        bufs[i], bufs[i + n] = bufs[i + n], bufs[i]
      end

      break
    end
  end

  vim.t.bufs = bufs
  vim.cmd("redrawtabline")
end

function M.goto_buf(bufnr)
  local cur_win = api.nvim_get_current_win()
  local fixedbuf = get_opt("winfixbuf", { win = cur_win })

  if fixedbuf then
    for _, win in ipairs(api.nvim_list_wins()) do
      local buflisted = get_opt("buflisted", { buf = api.nvim_win_get_buf(win) })
      local tmp_fixedbuf = get_opt("winfixbuf", { win = win })

      if buflisted and not tmp_fixedbuf then
        api.nvim_set_current_win(win)
        break
      end
    end
  end

  api.nvim_set_current_buf(bufnr)
end

return M

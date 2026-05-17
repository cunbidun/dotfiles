local M = {}

local config_dir = vim.fn.fnamemodify(vim.fn.stdpath("config"), ":p")
local real_config_dir = vim.fn.fnamemodify(vim.uv.fs_realpath(config_dir) or config_dir, ":p")

local config_dirs = { config_dir }
if real_config_dir ~= config_dir then
  table.insert(config_dirs, real_config_dir)
end

local function config_patterns()
  local patterns = {}

  for _, dir in ipairs(config_dirs) do
    table.insert(patterns, dir .. "init.lua")
    table.insert(patterns, dir .. "lua/user/**/*.lua")
  end

  return patterns
end

local function module_name(path)
  path = vim.fn.fnamemodify(path, ":p")

  for _, dir in ipairs(config_dirs) do
    local lua_dir = dir .. "lua/"
    if vim.startswith(path, lua_dir) and vim.endswith(path, ".lua") then
      return path:sub(#lua_dir + 1, -5):gsub("/", ".")
    end
  end
end

local function notify(message, level)
  vim.schedule(function()
    vim.notify(message, level or vim.log.levels.INFO, { title = "nvim reload" })
  end)
end

local function refresh_special(module)
  if module == "user.theme" then
    require("user.theme").apply()
  elseif module == "user.config.keymaps" then
    require("user.config.keymaps")
  elseif module == "user.config.conform" then
    require("user.config.conform")
  end
end

function M.reload_file(path)
  path = vim.fn.fnamemodify(path, ":p")

  for _, dir in ipairs(config_dirs) do
    if path == dir .. "init.lua" then
      notify("init.lua changed; restart Neovim to reload lazy.nvim setup", vim.log.levels.WARN)
      return false
    end
  end

  local module = module_name(path)
  if module then
    package.loaded[module] = nil
  end

  local ok, err = pcall(dofile, path)
  if not ok then
    notify("reload failed: " .. err, vim.log.levels.ERROR)
    return false
  end

  if module then
    local refresh_ok, refresh_err = pcall(refresh_special, module)
    if not refresh_ok then
      notify("refresh failed: " .. refresh_err, vim.log.levels.ERROR)
      return false
    end
  end

  notify("reloaded " .. vim.fn.fnamemodify(path, ":~:."))
  return true
end

function M.setup()
  local group = vim.api.nvim_create_augroup("UserConfigReload", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = config_patterns(),
    callback = function(args)
      M.reload_file(args.file)
    end,
  })
end

return M

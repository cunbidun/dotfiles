local M = {}

local function starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

function M.check()
  local health = vim.health or require("health")
  local ok, config = pcall(require, "lazy.core.config")
  if not ok then
    health.error("lazy.nvim config is not available")
    return
  end

  local plugin_root = vim.fn.fnamemodify(vim.fn.expand("~/.local/share/vim-plugins"), ":p")
  local missing = {}
  local outside_root = {}

  for name, plugin in pairs(config.plugins) do
    local dir = plugin.dir
    if type(dir) == "string" and dir ~= "" then
      local normalized = vim.fn.fnamemodify(dir, ":p")
      if starts_with(normalized, plugin_root) then
        if vim.fn.isdirectory(normalized) == 0 then
          missing[#missing + 1] = string.format("%s -> %s", name, normalized)
        end
      else
        outside_root[#outside_root + 1] = string.format("%s -> %s", name, normalized)
      end
    end
  end

  if #missing == 0 then
    health.ok("All lazy.nvim plugin directories under ~/.local/share/vim-plugins exist")
  else
    health.error(string.format("Missing %d plugin directories under ~/.local/share/vim-plugins", #missing))
    table.sort(missing)
    for _, line in ipairs(missing) do
      health.error(line)
    end
  end

  if #outside_root == 0 then
    health.ok("All resolved plugin dirs are under ~/.local/share/vim-plugins")
  else
    health.warn(string.format("%d plugins are outside ~/.local/share/vim-plugins", #outside_root))
    table.sort(outside_root)
    for _, line in ipairs(outside_root) do
      health.warn(line)
    end
  end
end

return M

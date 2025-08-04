local check_external_reqs = function()
  for _, exe in ipairs({
    "git",
    "unzip",
    "rg",
    "lua-language-server",
    "bash-language-server",
    "nixd",
    "pyright",
    "clangd",
  }) do
    local is_executable = vim.fn.executable(exe) == 1
    if is_executable then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end

  return true
end

return {
  check = function()
    vim.health.start("user.nvim")
    local uv = vim.uv or vim.loop
    vim.health.info("System Information: " .. vim.inspect(uv.os_uname()))
    check_external_reqs()
  end,
}

vim.cmd([[
  autocmd VimEnter * :silent exec "!kill -s SIGWINCH $PPID"
]])
require("core"):init()
require("plugins")

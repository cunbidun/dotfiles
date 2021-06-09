DATA_PATH = vim.fn.stdpath('data')
require'lspconfig'.texlab.setup {cmd = {DATA_PATH .. '/lspinstall/latex/texlab'}}

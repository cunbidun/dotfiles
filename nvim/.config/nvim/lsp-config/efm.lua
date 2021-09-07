DATA_PATH = vim.fn.stdpath('data')

require'lspconfig'.efm.setup {
  cmd = {DATA_PATH .. '/lspinstall/efm/efm-langserver'},
  init_options = {documentFormatting = true, codeAction = false},
  filetypes = {'lua', 'sh'},
  settings = {
    rootMarkers = {'.git/'},
    languages = {
      lua = {
        {
          formatCommand = 'lua-format -i --no-keep-simple-function-one-line --column-limit=120 --indent-width=2 --double-quote-to-single-quote',
          formatStdin = true
        }
      },
      sh = {
        {formatCommand = 'shfmt -ci -s -bn', formatStdin = true}, {
          LintCommand = 'shellcheck -f gcc -x',
          lintFormats = {'%f:%l:%c: %trror: %m', '%f:%l:%c: %tarning: %m', '%f:%l:%c: %tote: %m'}
        }
      }
    }
  }
}

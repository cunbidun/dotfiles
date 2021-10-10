local present, cmp = pcall(require, 'cmp')

if not present then return end

vim.opt.completeopt = 'menuone,noselect'

local icons = {
  Class = ' ',
  Color = ' ',
  Constant = 'ﲀ ',
  Constructor = ' ',
  Enum = '練',
  EnumMember = ' ',
  Event = ' ',
  Field = ' ',
  File = '',
  Folder = ' ',
  Function = ' ',
  Interface = 'ﰮ ',
  Keyword = ' ',
  Method = ' ',
  Module = ' ',
  Operator = '',
  Property = ' ',
  Reference = ' ',
  Snippet = ' ',
  Struct = ' ',
  Text = ' ',
  TypeParameter = ' ',
  Unit = '塞',
  Value = ' ',
  Variable = ' '
}
-- nvim-cmp setup
cmp.setup {
  snippet = {
    expand = function(args)
      vim.fn['vsnip#anonymous'](args.body)
    end
  },
  formatting = {
    format = function(entry, vim_item)
      vim_item.kind = icons[vim_item.kind]
      vim_item.menu = ({
        nvim_lsp = '(LSP)',
        emoji = '(Emoji)',
        path = '(Path)',
        calc = '(Calc)',
        cmp_tabnine = '(Tabnine)',
        vsnip = '(Snippet)',
        luasnip = '(Snippet)',
        buffer = '(Buffer)'
      })[entry.source.name]
      vim_item.dup = ({buffer = 1, path = 1, nvim_lsp = 0})[entry.source.name] or 0
      return vim_item
    end
  },
  mapping = {
    ['<C-k>'] = cmp.mapping.select_prev_item(),
    ['<C-j>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {behavior = cmp.ConfirmBehavior.Replace, select = true},
    ['<Tab>'] = function(fallback)
      if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-n>', true, true, true), 'n')
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-p>', true, true, true), 'n')
      else
        fallback()
      end
    end
  },
  sources = {
    {name = 'nvim_lsp'}, {name = 'nvim_lua'}, {name = 'buffer'}, {name = 'vsnip'}, {name = 'path'},
    {name = 'cmp_tabnine'}
    -- {name = 'emoji'}
  }
}

require('packer').startup(function()
  -- packer
  use "wbthomason/packer.nvim"

  -- nord theme
  use {
    "arcticicestudio/nord-vim",
    require("plugins.configs.nord-vim").setup(),
  }

  -- icons
  use "kyazdani42/nvim-web-devicons"

  -- bars
  use {
    'romgrk/barbar.nvim',
    requires = {{'kyazdani42/nvim-web-devicons'}},
    require("plugins.configs.barbar").setup(),
  }
  use {
    'glepnir/galaxyline.nvim',
    require("plugins.configs.galaxyline").setup(),
  }

  -- auto completion
  use "hrsh7th/vim-vsnip"
  use {
    "hrsh7th/nvim-cmp",
    commit = "af70f40", 
    require("plugins.configs.nvim-cmp").setup(),
  }
  use "hrsh7th/cmp-nvim-lsp"
  use "hrsh7th/cmp-nvim-lua"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-path" 
  use "hrsh7th/cmp-vsnip" 
  use {
    "tzachar/cmp-tabnine", 
    run = './install.sh'
  }

  -- treesitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ':TSUpdate',
    require("plugins.configs.nvim-treesitter").setup(),
  }
  use {
    'nvim-treesitter/nvim-treesitter-refactor',
    requires = {{"nvim-treesitter/nvim-treesitter"}}
  }
  
  -- lsp
  use {
    'neovim/nvim-lspconfig',
    require("plugins.configs.nvim-lspconfig").setup(),
  }
  use "kabouzeid/nvim-lspinstall"
  use { 
    'ahmedkhalf/project.nvim',
    require("plugins.configs.project").setup()
  }
  use {
    'ray-x/lsp_signature.nvim',
    require("plugins.configs.lsp_signature").setup()
  }
  use {
    'akinsho/nvim-toggleterm.lua',
    require("plugins.configs.nvim-toggleterm").setup(),
  }

  -- utils
  use "nvim-lua/plenary.nvim"
  use 'tpope/vim-surround'
  use {
    'terrortylor/nvim-comment',
    require("plugins.configs.nvim-comment").setup(),
  }
  use {
    'lukas-reineke/indent-blankline.nvim',
    require("plugins.configs.indent-blankline").setup(),
  }
  use {
   'unblevable/quick-scope',
   require("plugins.configs.quick-scope").setup(),
  }
  use {
    'windwp/nvim-autopairs',
    require("plugins.configs.nvim-autopairs").setup(),
  }
  use { 
    'norcalli/nvim-colorizer.lua',
    require("plugins.configs.nvim-colorizer").setup(),
  }
  use { 
    'karb94/neoscroll.nvim',
    require("plugins.configs.neoscroll").setup(),
  }
  use 'christoomey/vim-tmux-navigator'

  -- git 
  use { 
    'lewis6991/gitsigns.nvim',
    require("plugins.configs.gitsigns").setup(),
  }
  use { 
    'f-person/git-blame.nvim',
    require("plugins.configs.git-blame").setup(),
  }

  -- explorer
  use {
    'kevinhwang91/rnvimr',
    require("plugins.configs.rnvimr").setup(),
  }

  -- fzf
  use {
    'junegunn/fzf.vim',
    vim.cmd [[source $HOME/.config/nvim/lua/plugins/configs/fzf.vim]]
  }

  -- markdown
  use {
    'iamcco/markdown-preview.nvim',
    vim.cmd [[source $HOME/.config/nvim/lua/plugins/configs/markdown-preview.vim]]
  }
end)

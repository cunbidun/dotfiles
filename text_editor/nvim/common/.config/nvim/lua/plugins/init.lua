local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	Packer_bootstrap = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost init.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float({ border = 'single' })
    end,
  },
}

packer.startup(function(use)
-- 	-- packer
	use("wbthomason/packer.nvim")

	-- nord theme
	use({
		-- "shaunsingh/nord.nvim",
		"arcticicestudio/nord-vim",
		config = function()
			require("plugins.configs.nord-vim").setup()
		end,
	})

 	-- icons
 	use("kyazdani42/nvim-web-devicons")

	-- bars
	use({
		"romgrk/barbar.nvim",
		requires = { { "kyazdani42/nvim-web-devicons" } },
		config = function()
			require("plugins.configs.barbar").setup()
		end,
	})

	use({
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
		config = function()
			require("plugins.configs.lualine").setup()
		end,
	})
	-- auto completion
	use("hrsh7th/vim-vsnip")
	use({
		"hrsh7th/nvim-cmp",
		commit = "af70f40",
		config = function()
			require("plugins.configs.nvim-cmp").setup()
		end,
	})
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-nvim-lua")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-vsnip")
	use({"tzachar/cmp-tabnine", run = "./install.sh" })

	-- treesitter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
		config = function()
			require("plugins.configs.nvim-treesitter").setup()
		end,
	})
	use({ "nvim-treesitter/nvim-treesitter-refactor", requires = { { "nvim-treesitter/nvim-treesitter" } } })

	-- lsp
	use({
		"neovim/nvim-lspconfig",
		config = function()
			require("plugins.configs.nvim-lspconfig").setup()
		end,
	})
	use("williamboman/nvim-lsp-installer")
	use({
		"ahmedkhalf/project.nvim",
		config = function()
			require("plugins.configs.project").setup()
		end,
	})
	use({
		"ray-x/lsp_signature.nvim",
		config = function()
			require("plugins.configs.lsp_signature").setup()
		end,
	})
	use({
		"akinsho/nvim-toggleterm.lua",
		config = function()
			require("plugins.configs.nvim-toggleterm").setup()
		end,
	})
	use({
		"jose-elias-alvarez/null-ls.nvim",
		branch = "0.5.1-compat",
		config = function()
			require("plugins.configs.null-ls").setup()
		end,
		requires = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	})
	use({
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("plugins.configs.trouble").setup()
		end,
	})
	use({
		"simrat39/symbols-outline.nvim",
		config = function()
			require("plugins.configs.symbols-outline").setup()
		end,
	})

	-- motions
	use({
		"unblevable/quick-scope",
		config = function()
			require("plugins.configs.quick-scope").setup()
		end,
	})

	-- utils
	use("nvim-lua/plenary.nvim")
	use("tpope/vim-surround")
 	use({
 		"terrortylor/nvim-comment",
 		config = function()
 			require("plugins.configs.nvim-comment").setup()
 		end,
 	})
	use({
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("plugins.configs.indent-blankline").setup()
		end,
	})
	use({
		"windwp/nvim-autopairs",
		config = function()
			require("plugins.configs.nvim-autopairs").setup()
		end,
	})
	use({
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("plugins.configs.nvim-colorizer").setup()
		end,
	})
	use({
		"karb94/neoscroll.nvim",
		config = function()
			require("plugins.configs.neoscroll").setup()
		end,
	})
	use("christoomey/vim-tmux-navigator")

	use({
		"folke/todo-comments.nvim",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("plugins.configs.todo-comments").setup()
		end,
	})

	-- git
	use({ "lewis6991/gitsigns.nvim", require("plugins.configs.gitsigns").setup() })
	-- explorer
	use({
		"kevinhwang91/rnvimr",
		config = function()
			require("plugins.configs.rnvimr").setup()
		end,
	})
	-- use({
	-- 	"kyazdani42/nvim-tree.lua",
	-- 	requires = "kyazdani42/nvim-web-devicons",
	--     commit = "f92b7e7627c5a36f4af6814c408211539882c4f3",
	-- 	config = function()
	-- 		require("plugins.configs.nvim-tree").setup()
	-- 	end,
	-- })

	-- fzf
	use({
		"junegunn/fzf.vim",
		config = function()
			vim.cmd([[source $HOME/.config/nvim/lua/plugins/configs/fzf.vim]])
		end,
	})

	-- markdown
	use({
		"iamcco/markdown-preview.nvim",
		run = "cd app && yarn install",
		config = function()
			vim.cmd([[source $HOME/.config/nvim/lua/plugins/configs/markdown-preview.vim]])
		end,
	})

	-- latex
	use({
		"lervag/vimtex",
		config = function()
			vim.cmd([[
        let g:tex_flavor='latex'
        let g:vimtex_view_method='zathura'
        let g:vimtex_quickfix_mode=0
      ]])
		end,
	})

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if Packer_bootstrap then
		require("packer").sync()
	end
end)
local present, lspconfig = pcall(require, "lspconfig")

local M = {
	setup = function() end,
}

if not present then
	return M
end

DATA_PATH = vim.fn.stdpath("data")
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

local servers = {
	bashls = {
		capabilities = capabilities,
		on_attach = function(client)
			client.resolved_capabilities.document_formatting = false
		end,
		cmd = { DATA_PATH .. "/lspinstall/bash/node_modules/.bin/bash-language-server", "start" },
		filetypes = { "sh", "zsh" },
	},
	clangd = {
		capabilities = capabilities,
		cmd = {
			DATA_PATH .. "/lspinstall/cpp/clangd/bin/clangd",
			"--background-index",
			"--header-insertion=never",
			"--cross-file-rename",
			"--clang-tidy",
			"--clang-tidy-checks=-*,llvm-*,clang-analyzer-*",
		},
		on_attach = function(client)
			client.resolved_capabilities.document_formatting = true
		end,
		handlers = {
			["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
				virtual_text = true,
				signs = true,
				underline = true,
				update_in_insert = true,
			}),
		},
	},
	jsonls = {
		capabilities = capabilities,
		cmd = {
			"node",
			DATA_PATH .. "/lspinstall/json/vscode-json/json-language-features/server/dist/node/jsonServerMain.js",
			"--stdio",
		},
		on_attach = function(client)
			client.resolved_capabilities.document_formatting = true
		end,
		commands = {
			Format = {
				function()
					vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line("$"), 0 })
				end,
			},
		},
	},
	hls = {
		capabilities = capabilities,
		cmd = { DATA_PATH .. "/lspinstall/haskell/haskell-language-server-wrapper", "--lsp" },
		on_attach = function(client)
			client.resolved_capabilities.document_formatting = true
			client.resolved_capabilities.document_range_formatting = true
		end,
	},
	sumneko_lua = {
		capabilities = capabilities,
		cmd = {
			DATA_PATH .. "/lspinstall/lua/sumneko-lua-language-server",
			"-E",
			DATA_PATH .. "/lspinstall/lua/main.lua",
		},
		on_attach = function(client)
			client.resolved_capabilities.document_formatting = false
		end,
		settings = {
			Lua = {
				runtime = {
					-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
					version = "LuaJIT",
					-- Setup your lua path
					path = vim.split(package.path, ";"),
				},
				diagnostics = {
					-- Get the language server to recognize the `vim` global
					globals = { "vim" },
				},
				workspace = {
					-- Make the server aware of Neovim runtime files
					library = {
						[vim.fn.expand("$VIMRUNTIME/lua")] = true,
						[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
					},
					maxPreload = 10000,
				},
			},
		},
	},
	pyright = {
		capabilities = capabilities,
		cmd = { DATA_PATH .. "/lspinstall/python/node_modules/.bin/pyright-langserver", "--stdio" },
		on_attach = function(client)
			client.resolved_capabilities.document_formatting = false
			client.resolved_capabilities.document_range_formatting = false
		end,
	},
	vimls = {
		capabilities = capabilities,
		cmd = { DATA_PATH .. "/lspinstall/vim/node_modules/.bin/vim-language-server", "--stdio" },
	},
	texlab = {
		capabilities = capabilities,
		cmd = { DATA_PATH .. "/lspinstall/latex/texlab" },
		on_attach = function(client)
			client.resolved_capabilities.document_formatting = true
		end,
		commands = {
			Format = {
				function()
					vim.cmd([[!latexindent -y="defaultIndent:'\t',onlyOneBackUp: 1" '%:t' -w -m -s]])
				end,
			},
		},
	},
}

M.setup = function()
	vim.api.nvim_set_keymap(
		"n",
		"<leader>d",
		"<cmd>lua vim.lsp.buf.definition()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap("n", "<leader>h", "<cmd>lua vim.lsp.buf.hover()<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap(
		"n",
		"<leader>r",
		"<cmd>lua vim.lsp.buf.references()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { noremap = true, silent = true })
	vim.api.nvim_set_keymap(
		"n",
		"<leader>ca",
		"<cmd>lua vim.lsp.buf.code_action()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap(
		"n",
		"<leader>h",
		"<cmd>lua vim.lsp.buf.definition()<CR>",
		{ noremap = true, silent = true }
	)
	vim.api.nvim_set_keymap("n", "<C-M-l>", "<cmd>lua vim.lsp.buf.formatting()<CR>", { noremap = true, silent = true })

	-- Use a loop to conveniently call 'setup' on multiple servers and
	for k, v in pairs(servers) do
		lspconfig[k].setup(v)
	end
end

return M

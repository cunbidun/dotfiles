local present, lualine = pcall(require, "lualine")

local M = { setup = function() end }

if not present then
	return M
end

local colors = {
	fg = "#D8DEE9",
	darkblue = "#5E81AC",
	violet = "#B48EAD",
	bg = "#434C5E",
	yellow = "#EBCB8B",
	dark_yellow = "#EBCB8B",
	info_yellow = "#EBCB8B",
	green = "#A3BE8C",
	light_green = "#A3BE8C",
	string_orange = "#D08770",
	orange = "#D08770",
	red = "#BF616A",
	error_red = "#BF616A",
	cyan = "#88C0D0",
	vivid_blue = "#88C0D0",
	purple = "#B48EAD",
	magenta = "#B48EAD",
	blue = "#81A1C1",
	light_blue = "#8FBCBB",
	grey = "#D8DEE9",
}

-- conditions --
local window_width_limit = 80
local conditions = {
	buffer_not_empty = function()
		return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
	end,
	hide_in_width = function()
		return vim.fn.winwidth(0) > window_width_limit
	end,
}

local function diff_source()
	local gitsigns = vim.b.gitsigns_status_dict
	if gitsigns then
		return {
			added = gitsigns.added,
			modified = gitsigns.changed,
			removed = gitsigns.removed,
		}
	end
end

local components = {
	mode = {
		function()
			return " "
		end,
		padding = { left = 0, right = 0 },
		color = {},
		cond = nil,
	},
	branch = {
		"b:gitsigns_head",
		icon = " ",
		color = { gui = "bold" },
		cond = conditions.hide_in_width,
	},
	filename = {
		"filename",
		color = {},
		cond = nil,
	},
	diff = {
		"diff",
		source = diff_source,
		symbols = { added = "  ", modified = "柳", removed = " " },
		diff_color = {
			added = { fg = colors.green },
			modified = { fg = colors.yellow },
			removed = { fg = colors.red },
		},
		color = {},
		cond = nil,
	},
	python_env = {
		function()
			local utils = {}
			utils.env_cleanup = function(venv)
				if string.find(venv, "/") then
					local final_venv = venv
					for w in venv:gmatch("([^/]+)") do
						final_venv = w
					end
					venv = final_venv
				end
				return venv
			end
			if vim.bo.filetype == "python" then
				local venv = os.getenv("CONDA_DEFAULT_ENV")
				if venv then
					return string.format("  (%s)", utils.env_cleanup(venv))
				end
				venv = os.getenv("VIRTUAL_ENV")
				if venv then
					return string.format("  (%s)", utils.env_cleanup(venv))
				end
				return ""
			end
			return ""
		end,
		color = { fg = colors.green },
		cond = conditions.hide_in_width,
	},
	diagnostics = {
		"diagnostics",
		sources = { "nvim_lsp" },
		symbols = { error = " ", warn = " ", info = " ", hint = " " },
		color = {},
		cond = conditions.hide_in_width,
	},
	treesitter = {
		function()
			local b = vim.api.nvim_get_current_buf()
			if vim.treesitter.highlighter.active[b] == nil then
				return ""
			end
			if next(vim.treesitter.highlighter.active[b]) then
				return "  "
			end
			return ""
		end,
		color = { fg = colors.green },
		cond = conditions.hide_in_width,
	},
	lsp = {
		function(msg)
			msg = msg or "LS Inactive"
			local buf_clients = vim.lsp.buf_get_clients()
			if next(buf_clients) == nil then
				-- TODO: clean up this if statement
				if type(msg) == "boolean" or #msg == 0 then
					return "LS Inactive"
				end
				return msg
			end
			local buf_ft = vim.bo.filetype
			local buf_client_names = {}

			-- add client
			for _, client in pairs(buf_clients) do
				if client.name ~= "null-ls" then
					table.insert(buf_client_names, client.name)
				end
			end

			local services = {
				list_registered_providers_names = function(filetype)
					local u = require("null-ls.utils")
					local c = require("null-ls.config")
					local registered = {}
					for method, source in pairs(c.get()._methods) do
						for name, filetypes in pairs(source) do
							if u.filetype_matches(filetypes, filetype) then
								registered[method] = registered[method] or {}
								table.insert(registered[method], name)
							end
						end
					end
					return registered
				end,
			}

      -- add formatters
			local formatters = {
				list_registered_providers = function(filetype)
					local null_ls_methods = require("null-ls.methods")
					local formatter_method = null_ls_methods.internal["FORMATTING"]
					local registered_providers = services.list_registered_providers_names(filetype)
					return registered_providers[formatter_method] or {}
				end,
			}
			local supported_formatters = formatters.list_registered_providers(buf_ft)
			vim.list_extend(buf_client_names, supported_formatters)

			-- add linter
			local linters = {
				list_registered_providers = function(filetype)
					local null_ls_methods = require("null-ls.methods")
					local linter_method = null_ls_methods.internal["DIAGNOSTICS"]
					local registered_providers = services.list_registered_providers_names(filetype)
					return registered_providers[linter_method] or {}
				end,
			}
			local supported_linters = linters.list_registered_providers(buf_ft)
			vim.list_extend(buf_client_names, supported_linters)

			return table.concat(buf_client_names, ", ")
		end,
		icon = " ",
		color = { gui = "bold" },
		cond = conditions.hide_in_width,
	},
	location = { "location", cond = conditions.hide_in_width, color = {} },
	progress = { "progress", cond = conditions.hide_in_width, color = {} },
	spaces = {
		function()
			if not vim.api.nvim_buf_get_option(0, "expandtab") then
				return "Tab size: " .. vim.api.nvim_buf_get_option(0, "tabstop") .. " "
			end
			local size = vim.api.nvim_buf_get_option(0, "shiftwidth")
			if size == 0 then
				size = vim.api.nvim_buf_get_option(0, "tabstop")
			end
			return "Spaces: " .. size .. " "
		end,
		cond = conditions.hide_in_width,
		color = {},
	},
	encoding = {
		"o:encoding",
		fmt = string.upper,
		color = {},
		cond = conditions.hide_in_width,
	},
	filetype = { "filetype", cond = conditions.hide_in_width, color = {} },
	scrollbar = {
		function()
			local current_line = vim.fn.line(".")
			local total_lines = vim.fn.line("$")
			local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
			local line_ratio = current_line / total_lines
			local index = math.ceil(line_ratio * #chars)
			return chars[index]
		end,
		padding = { left = 0, right = 0 },
		color = { fg = colors.yellow, bg = colors.bg },
		cond = nil,
	},
}
M.setup = function()
	lualine.setup({
		options = {
			icons_enabled = true,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			disabled_filetypes = { "dashboard", "NvimTree", "Outline" },
		},
		sections = {
			lualine_a = {
				-- components.mode,
				{ "mode" },
			},
			lualine_b = {
				components.branch,
				components.filename,
			},
			lualine_c = {
				components.diff,
				components.python_env,
			},
			lualine_x = {
				components.diagnostics,
				components.treesitter,
				components.lsp,
				components.filetype,
			},
			lualine_y = {},
			lualine_z = {
				components.scrollbar,
			},
		},
		inactive_sections = {
			lualine_a = {
				"filename",
			},
			lualine_b = {},
			lualine_c = {},
			lualine_x = {},
			lualine_y = {},
			lualine_z = {},
		},
		tabline = {},
		extensions = nil,
		on_config_done = nil,
	})
end

return M

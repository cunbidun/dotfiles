local present, indent_blankline = pcall(require, 'indent_blankline')

local M = {setup = function() end}

if not present then 
  return M 
end

M.setup = function()
	indent_blankline.setup {
		indentLine_enabled = 1,
		char = '▏',
		filetype_exclude = {'help', 'terminal', 'dashboard', 'packer', 'lspinfo', 'TelescopePrompt', 'TelescopeResults'},
		buftype_exclude = {'terminal'},
		show_trailing_blankline_indent = false,
		show_first_indent_level = false,
		show_current_context = true,
		use_treesitter = true
	}

	vim.g.indent_blankline_context_patterns = {
		'^for', '^if', '^object', '^table', '^while', 'arguments', 'block', 'catch_clause', 'class', 'else_clause',
		'function', 'if_statement', 'import_statement', 'jsx_element', 'jsx_element', 'jsx_self_closing_element', 'method',
		'operation_type', 'return', 'try_statement'
	}
	vim.g.indent_blankline_use_treesitter = true
end

return M
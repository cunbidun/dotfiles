local present, colorizer = pcall(require, 'colorizer')

local M = {setup = function() end}

if not present then 
  return M 
end

M.setup = function()
	colorizer.setup(
		{'*';},
		{
			RGB      = true;         -- #RGB hex codes
			RRGGBB   = true;         -- #RRGGBB hex codes
			RRGGBBAA = true;         -- #RRGGBBAA hex codes
			rgb_fn   = true;         -- CSS rgb() and rgba() functions
			hsl_fn   = true;         -- CSS hsl() and hsla() functions
			css      = true;         -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
			css_fn   = true;         -- Enable all CSS *functions*: rgb_fn, hsl_fn
		})
end

return M
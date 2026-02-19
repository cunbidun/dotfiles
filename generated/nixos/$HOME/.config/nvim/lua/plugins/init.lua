M1 = require "plugins.init-1"
M2 = require "plugins.init-2"
for i = 1, #M2 do
  M1[#M1 + 1] = M2[i]
end
return M1

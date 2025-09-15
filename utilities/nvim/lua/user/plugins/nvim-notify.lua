return {
  "rcarriga/nvim-notify",
  name = "nvim-notify",
  dev = true,
  lazy = false,
  priority = 1000, -- Load early since other plugins might use notifications
  config = function()
    local notify = require("notify")
    
    -- Configure nvim-notify
    notify.setup({
      -- Animation style
      stages = "fade_in_slide_out",
      
      -- Timeout for notifications
      timeout = 3000,
      
      -- Background colour
      background_colour = "Normal",
      
      -- Icons for different levels
      icons = {
        ERROR = "",
        WARN = "",
        INFO = "",
        DEBUG = "",
        TRACE = "✎",
      },
      
      -- Minimum width and maximum width
      minimum_width = 50,
      max_width = 80,
      max_height = 10,
      
      -- Position
      top_down = true,
    })
    
    -- Set as the default notification handler
    vim.notify = notify
  end,
}
" NOTE: If barbar's option dict isn't created yet, create it
let bufferline = get(g:, 'bufferline', {})

lua <<EOF
vim.api.nvim_set_keymap('n', '<TAB>', ':BufferNext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<S-TAB>', ':BufferPrevious<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<S-x>', ':BufferClose<CR>', { noremap = true, silent = true })
EOF

" Enable/disable animations
let bufferline.animation = v:false
let bufferline.icon_custom_colors = v:true

let bufferline.maximum_length = 20 
let bufferline.maximum_padding = 1 

" Enable/disable close button
let bufferline.closable = v:false

" Enables/disable clickable tabs
"  - left-click: go to buffer
"  - middle-click: delete buffer
let bufferline.clickable = v:false

" Enable/disable current/total tabpages indicator (top right corner)
let bufferline.tabpages = v:true

-- Example configuration for jjsigns.nvim

-- Basic setup with default options
require('jjsigns').setup()

-- Or with custom configuration
require('jjsigns').setup({
  enabled = true,
  
  attach = {
    auto = true,  -- Automatically attach to JJ repository files
  },
  
  signs = {
    -- Using exact same characters as gitsigns defaults
    add = { text = '┃', numhl = 'JjSignsAddNr', linehl = 'JjSignsAddLn' },
    change = { text = '┃', numhl = 'JjSignsChangeNr', linehl = 'JjSignsChangeLn' },
    delete = { text = '▁', numhl = 'JjSignsDeleteNr', linehl = 'JjSignsDeleteLn' },
    topdelete = { text = '▔', numhl = 'JjSignsDeleteNr', linehl = 'JjSignsDeleteLn' },
    changedelete = { text = '~', numhl = 'JjSignsChangeNr', linehl = 'JjSignsChangeLn' },
  },
  
  sign_priority = 6,
  signcolumn = true,   -- Show signs in sign column
  numhl = false,       -- Highlight line numbers
  linehl = false,      -- Highlight entire lines
  
  -- JJ specific options
  base = '@-',         -- Base revision to compare against
  
  -- Performance options
  update_debounce = 100,  -- Debounce updates in milliseconds
})

-- Example keymaps (optional)
vim.keymap.set('n', '<leader>jt', '<cmd>JjSigns toggle<cr>', { desc = 'Toggle JjSigns' })
vim.keymap.set('n', '<leader>js', '<cmd>JjSigns toggle_signs<cr>', { desc = 'Toggle sign column' })
vim.keymap.set('n', '<leader>jn', '<cmd>JjSigns toggle_numhl<cr>', { desc = 'Toggle number highlighting' })
vim.keymap.set('n', '<leader>jl', '<cmd>JjSigns toggle_linehl<cr>', { desc = 'Toggle line highlighting' })

-- Custom highlight groups (optional)
vim.api.nvim_set_hl(0, 'JjSignsAdd', { fg = '#a7c080', bold = true })
vim.api.nvim_set_hl(0, 'JjSignsChange', { fg = '#7fbbb3', bold = true })
vim.api.nvim_set_hl(0, 'JjSignsDelete', { fg = '#e67e80', bold = true })
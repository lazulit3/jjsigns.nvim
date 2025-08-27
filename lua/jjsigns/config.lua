local M = {}

--- @class JjSignsConfig
local default_config = {
  enabled = true,

  attach = {
    auto = true,
  },

  signs = {
    add = { text = '┃', numhl = 'JjSignsAddNr', linehl = 'JjSignsAddLn' },
    change = { text = '┃', numhl = 'JjSignsChangeNr', linehl = 'JjSignsChangeLn' },
    delete = { text = '▁', numhl = 'JjSignsDeleteNr', linehl = 'JjSignsDeleteLn' },
    topdelete = { text = '▔', numhl = 'JjSignsDeleteNr', linehl = 'JjSignsDeleteLn' },
    changedelete = { text = '~', numhl = 'JjSignsChangeNr', linehl = 'JjSignsChangeLn' },
  },

  sign_priority = 6,
  signcolumn = true, -- Toggle with `:JjSigns toggle_signs`
  numhl = false, -- Toggle with `:JjSigns toggle_numhl`
  linehl = false, -- Toggle with `:JjSigns toggle_linehl`

  -- JJ specific options
  base = '@-', -- Base revision to compare against (default: parent revision)

  -- Performance options
  update_debounce = 100, -- Debounce time for updates in milliseconds
}

M.config = vim.deepcopy(default_config)

--- Setup configuration
--- @param user_config table? User configuration options
function M.setup(user_config)
  if user_config then
    M.config = vim.tbl_deep_extend('force', M.config, user_config)
  end
end

return M

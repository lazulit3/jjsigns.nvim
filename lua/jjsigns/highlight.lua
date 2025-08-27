local api = vim.api

local M = {}

-- Define default highlight groups
local highlights = {
  -- Sign column highlights
  JjSignsAdd = { link = 'GitSignsAdd' },
  JjSignsChange = { link = 'GitSignsChange' },
  JjSignsDelete = { link = 'GitSignsDelete' },
  JjSignsChangedelete = { link = 'GitSignsChange' },
  JjSignsTopdelete = { link = 'GitSignsDelete' },

  -- Number column highlights
  JjSignsAddNr = { link = 'GitSignsAddNr' },
  JjSignsChangeNr = { link = 'GitSignsChangeNr' },
  JjSignsDeleteNr = { link = 'GitSignsDeleteNr' },
  JjSignsChangedeleteNr = { link = 'GitSignsChangeNr' },
  JjSignsTopdeleteNr = { link = 'GitSignsDeleteNr' },

  -- Line highlights
  JjSignsAddLn = { link = 'GitSignsAddLn' },
  JjSignsChangeLn = { link = 'GitSignsChangeLn' },
  JjSignsDeleteLn = { link = 'GitSignsDeleteLn' },
  JjSignsChangedeleteLn = { link = 'GitSignsChangeLn' },
  JjSignsTopdeleteLn = { link = 'GitSignsDeleteLn' },
}

-- Fallback highlights if GitSigns* groups don't exist
local fallback_highlights = {
  -- Sign column highlights
  JjSignsAdd = { fg = '#587c0c' },
  JjSignsChange = { fg = '#0c7d9d' },
  JjSignsDelete = { fg = '#94151b' },
  JjSignsChangedelete = { fg = '#0c7d9d' },
  JjSignsTopdelete = { fg = '#94151b' },

  -- Number column highlights
  JjSignsAddNr = { fg = '#587c0c' },
  JjSignsChangeNr = { fg = '#0c7d9d' },
  JjSignsDeleteNr = { fg = '#94151b' },
  JjSignsChangedeleteNr = { fg = '#0c7d9d' },
  JjSignsTopdeleteNr = { fg = '#94151b' },

  -- Line highlights (subtle background colors)
  JjSignsAddLn = { bg = '#2d4016' },
  JjSignsChangeLn = { bg = '#1e3a42' },
  JjSignsDeleteLn = { bg = '#45161a' },
  JjSignsChangedeleteLn = { bg = '#1e3a42' },
  JjSignsTopdeleteLn = { bg = '#45161a' },
}

--- Setup highlight groups
function M.setup()
  -- First, try to link to GitSigns highlights
  for name, opts in pairs(highlights) do
    local link_target = opts.link
    -- Check if the link target exists
    if vim.fn.hlexists(link_target) == 1 then
      api.nvim_set_hl(0, name, opts)
    else
      -- Fall back to our own colors
      local fallback = fallback_highlights[name]
      if fallback then
        api.nvim_set_hl(0, name, fallback)
      end
    end
  end
end

return M

local api = vim.api
local config = require('jjsigns.config')

local M = {}

-- Namespace for signs
local ns = api.nvim_create_namespace('jjsigns')

-- Store buffer data
local buffer_data = {}

--- @class JjSignData
--- @field line integer
--- @field type string

--- Clear all signs from a buffer
--- @param bufnr integer
function M.clear_buffer(bufnr)
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  buffer_data[bufnr] = nil
end

--- Clear all signs from all buffers
function M.clear_all()
  for bufnr in pairs(buffer_data) do
    if api.nvim_buf_is_valid(bufnr) then
      M.clear_buffer(bufnr)
    end
  end
  buffer_data = {}
end

--- Get highlight group for a sign type and highlight kind
--- @param sign_type string
--- @param hl_kind string 'text' | 'numhl' | 'linehl'
--- @return string?
local function get_sign_hl(sign_type, hl_kind)
  local sign_config = config.config.signs[sign_type]
  if not sign_config then
    return nil
  end

  if hl_kind == 'text' then
    return 'JjSigns' .. sign_type:sub(1, 1):upper() .. sign_type:sub(2)
  elseif hl_kind == 'numhl' then
    return sign_config.numhl
  elseif hl_kind == 'linehl' then
    return sign_config.linehl
  end

  return nil
end

--- Place signs on a buffer
--- @param bufnr integer Buffer number
--- @param signs JjSignData[] Array of sign data
function M.place_signs(bufnr, signs)
  -- Clear existing signs first
  M.clear_buffer(bufnr)

  -- Store buffer data
  buffer_data[bufnr] = {
    signs = signs,
    last_update = vim.loop.hrtime(),
  }

  -- Place new signs
  for _, sign_data in ipairs(signs) do
    local line = sign_data.line - 1 -- Convert to 0-indexed
    local sign_type = sign_data.type
    local sign_config = config.config.signs[sign_type]

    if sign_config then
      local opts = {
        id = line + 1, -- Use line number as ID (1-indexed)
        priority = config.config.sign_priority,
      }

      -- Add sign column text
      if config.config.signcolumn then
        opts.sign_text = sign_config.text
        opts.sign_hl_group = get_sign_hl(sign_type, 'text')
      end

      -- Add number column highlighting
      if config.config.numhl then
        opts.number_hl_group = get_sign_hl(sign_type, 'numhl')
      end

      -- Add line highlighting
      if config.config.linehl then
        opts.line_hl_group = get_sign_hl(sign_type, 'linehl')
      end

      local ok, err = pcall(api.nvim_buf_set_extmark, bufnr, ns, line, 0, opts)
      if not ok then
        vim.notify(
          'JjSigns: Failed to place sign at line ' .. sign_data.line .. ': ' .. err,
          vim.log.levels.WARN
        )
      end
    end
  end
end

--- Update signs for a buffer
--- @param bufnr integer Buffer number
--- @param filepath string Absolute file path
--- @param repo_root string Repository root path
function M.update_buffer_signs(bufnr, filepath, repo_root)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Skip if buffer is not normal file
  local buftype = vim.bo[bufnr].buftype
  if buftype ~= '' then
    return
  end

  local diff = require('jjsigns.diff')
  local hunks = diff.get_file_hunks(filepath, repo_root, config.config.base)
  local signs = diff.hunks_to_signs(hunks)

  M.place_signs(bufnr, signs)
end

--- Get signs data for a buffer
--- @param bufnr integer
--- @return JjSignData[]?
function M.get_buffer_signs(bufnr)
  local data = buffer_data[bufnr]
  return data and data.signs or nil
end

--- Check if a buffer has signs
--- @param bufnr integer
--- @return boolean
function M.has_signs(bufnr)
  local data = buffer_data[bufnr]
  return data ~= nil and data.signs and #data.signs > 0
end

--- Toggle signcolumn display
function M.toggle_signcolumn()
  config.config.signcolumn = not config.config.signcolumn
  M.refresh_all_buffers()
end

--- Toggle number column highlighting
function M.toggle_numhl()
  config.config.numhl = not config.config.numhl
  M.refresh_all_buffers()
end

--- Toggle line highlighting
function M.toggle_linehl()
  config.config.linehl = not config.config.linehl
  M.refresh_all_buffers()
end

--- Refresh signs for all buffers
function M.refresh_all_buffers()
  local attach = require('jjsigns.attach')

  for bufnr in pairs(buffer_data) do
    if api.nvim_buf_is_valid(bufnr) then
      local filepath = api.nvim_buf_get_name(bufnr)
      if filepath ~= '' then
        attach.update_buffer(bufnr, filepath)
      end
    end
  end
end

return M

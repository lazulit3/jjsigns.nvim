local api = vim.api
local config = require('jjsigns.config')
local jj = require('jjsigns.jj')
local signs = require('jjsigns.signs')

local M = {}

-- Store buffer state
local buffer_state = {}

-- Debounce timers for updates
local update_timers = {}

--- @class JjBufferState
--- @field repo_root string Repository root path
--- @field attached boolean Whether signs are attached
--- @field autocmds integer[] Autocmd IDs

--- Check if a buffer should be attached
--- @param bufnr integer
--- @return boolean
local function should_attach(bufnr)
  -- Don't attach to invalid buffers
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- Don't attach to special buffers
  local buftype = vim.bo[bufnr].buftype
  if buftype ~= '' then
    return false
  end

  -- Don't attach to unnamed buffers
  local filepath = api.nvim_buf_get_name(bufnr)
  if filepath == '' then
    return false
  end

  return true
end

--- Debounced update function
--- @param bufnr integer
--- @param filepath string
local function update_buffer_debounced(bufnr, filepath)
  -- Cancel existing timer
  local existing_timer = update_timers[bufnr]
  if existing_timer then
    existing_timer:stop()
    existing_timer:close()
  end

  -- Create new timer
  update_timers[bufnr] = vim.defer_fn(function()
    update_timers[bufnr] = nil
    M.update_buffer(bufnr, filepath)
  end, config.config.update_debounce)
end

--- Update signs for a buffer
--- @param bufnr integer
--- @param filepath string
function M.update_buffer(bufnr, filepath)
  if not should_attach(bufnr) then
    return
  end

  local state = buffer_state[bufnr]
  if not state or not state.attached then
    return
  end

  signs.update_buffer_signs(bufnr, filepath, state.repo_root)
end

--- Detach from a buffer
--- @param bufnr integer
function M.detach_buffer(bufnr)
  local state = buffer_state[bufnr]
  if not state then
    return
  end

  -- Clear signs
  signs.clear_buffer(bufnr)

  -- Remove autocmds
  for _, autocmd_id in ipairs(state.autocmds or {}) do
    pcall(api.nvim_del_autocmd, autocmd_id)
  end

  -- Cancel any pending update
  local timer = update_timers[bufnr]
  if timer then
    timer:stop()
    timer:close()
    update_timers[bufnr] = nil
  end

  -- Clear state
  buffer_state[bufnr] = nil
end

--- Attach to a buffer
--- @param bufnr integer
function M.attach_to_buffer(bufnr)
  if not config.config.enabled then
    return
  end

  if not should_attach(bufnr) then
    return
  end

  local filepath = api.nvim_buf_get_name(bufnr)
  local file_dir = vim.fs.dirname(filepath)

  -- Check if we're in a JJ repository
  if not jj.is_jj_repo(file_dir) then
    return
  end

  local repo_root = jj.get_repo_root(file_dir)
  if not repo_root then
    return
  end

  -- Check if file is tracked
  local rel_path = filepath:sub(#repo_root + 2)
  if not jj.is_file_tracked(rel_path, repo_root) then
    return
  end

  -- Detach first if already attached
  if buffer_state[bufnr] then
    M.detach_buffer(bufnr)
  end

  -- Setup autocmds for this buffer
  local group = api.nvim_create_augroup('jjsigns_buffer_' .. bufnr, { clear = true })
  local autocmds = {}

  -- Update on text changes
  table.insert(
    autocmds,
    api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
      group = group,
      buffer = bufnr,
      callback = function()
        update_buffer_debounced(bufnr, filepath)
      end,
    })
  )

  -- Update on buffer write
  table.insert(
    autocmds,
    api.nvim_create_autocmd('BufWritePost', {
      group = group,
      buffer = bufnr,
      callback = function()
        M.update_buffer(bufnr, filepath)
      end,
    })
  )

  -- Cleanup on buffer unload
  table.insert(
    autocmds,
    api.nvim_create_autocmd('BufUnload', {
      group = group,
      buffer = bufnr,
      callback = function()
        M.detach_buffer(bufnr)
      end,
    })
  )

  -- Store buffer state
  buffer_state[bufnr] = {
    repo_root = repo_root,
    attached = true,
    autocmds = autocmds,
  }

  -- Initial sign update
  M.update_buffer(bufnr, filepath)
end

--- Get buffer state
--- @param bufnr integer
--- @return JjBufferState?
function M.get_buffer_state(bufnr)
  return buffer_state[bufnr]
end

--- Check if buffer is attached
--- @param bufnr integer
--- @return boolean
function M.is_attached(bufnr)
  local state = buffer_state[bufnr]
  return state ~= nil and state.attached
end

--- Detach from all buffers
function M.detach_all()
  for bufnr in pairs(buffer_state) do
    M.detach_buffer(bufnr)
  end
end

--- Refresh all attached buffers
function M.refresh_all()
  for bufnr, state in pairs(buffer_state) do
    if api.nvim_buf_is_valid(bufnr) and state.attached then
      local filepath = api.nvim_buf_get_name(bufnr)
      M.update_buffer(bufnr, filepath)
    end
  end
end

return M

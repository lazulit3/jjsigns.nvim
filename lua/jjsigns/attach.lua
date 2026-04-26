local api = vim.api
local config = require('jjsigns.config')
local jj = require('jjsigns.jj')
local signs = require('jjsigns.signs')

local M = {}

--- @class JjBufferState
--- @field repo_root string
--- @field rel_path string
--- @field base_lines string[]? Lines of the file at config.base; nil while loading
--- @field attached boolean
--- @field autocmds integer[]
--- @field request_id integer Monotonic counter; stale callbacks no-op when their id ≠ this
local buffer_state = {}

local update_timers = {}

--- @param bufnr integer
--- @return boolean
local function should_attach(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end
  if vim.bo[bufnr].buftype ~= '' then
    return false
  end
  if api.nvim_buf_get_name(bufnr) == '' then
    return false
  end
  return true
end

--- Recompute and place signs for a buffer using its cached base.
--- Cheap: no subprocess, no I/O.
--- @param bufnr integer
function M.update_buffer(bufnr)
  if not should_attach(bufnr) then
    return
  end
  local state = buffer_state[bufnr]
  if not state or not state.attached or not state.base_lines then
    return
  end
  signs.update_buffer_signs(bufnr, state.base_lines)
end

--- @param bufnr integer
local function update_buffer_debounced(bufnr)
  local existing = update_timers[bufnr]
  if existing then
    existing:stop()
    existing:close()
  end
  update_timers[bufnr] = vim.defer_fn(function()
    update_timers[bufnr] = nil
    M.update_buffer(bufnr)
  end, config.config.update_debounce)
end

--- @param bufnr integer
function M.detach_buffer(bufnr)
  local state = buffer_state[bufnr]
  if not state then
    return
  end

  signs.clear_buffer(bufnr)

  for _, autocmd_id in ipairs(state.autocmds or {}) do
    pcall(api.nvim_del_autocmd, autocmd_id)
  end

  local timer = update_timers[bufnr]
  if timer then
    timer:stop()
    timer:close()
    update_timers[bufnr] = nil
  end

  buffer_state[bufnr] = nil
end

--- (Re-)read base content for an already-attached buffer and refresh signs.
--- @param bufnr integer
local function reload_base(bufnr)
  local state = buffer_state[bufnr]
  if not state or not state.attached then
    return
  end

  state.request_id = state.request_id + 1
  local req = state.request_id
  local repo_root = state.repo_root
  local rel_path = state.rel_path

  jj.get_file_content(rel_path, config.config.base, repo_root, function(lines)
    local s = buffer_state[bufnr]
    if not s or s.request_id ~= req or not s.attached then
      return
    end
    -- Files added in the working copy don't exist at @-; treat as empty.
    s.base_lines = lines or {}
    M.update_buffer(bufnr)
  end)
end

--- Attach to a buffer asynchronously. Subprocess work runs off the autocmd hot path.
--- @param bufnr integer
function M.attach_to_buffer(bufnr)
  if not config.config.enabled then
    return
  end
  if not should_attach(bufnr) then
    return
  end

  if buffer_state[bufnr] then
    M.detach_buffer(bufnr)
  end

  local filepath = api.nvim_buf_get_name(bufnr)
  local file_dir = vim.fs.dirname(filepath)

  jj.get_repo_root(file_dir, function(repo_root)
    if not repo_root or not api.nvim_buf_is_valid(bufnr) then
      return
    end
    if api.nvim_buf_get_name(bufnr) ~= filepath then
      -- Buffer was renamed mid-flight; bail.
      return
    end

    local rel_path = filepath
    if vim.startswith(filepath, repo_root) then
      rel_path = filepath:sub(#repo_root + 2)
    end

    jj.is_file_tracked(rel_path, repo_root, function(tracked)
      if not tracked or not api.nvim_buf_is_valid(bufnr) then
        return
      end

      -- Set up state and autocmds before the base content arrives so that
      -- early TextChanged events have somewhere to land (they no-op until
      -- base_lines is populated).
      local group = api.nvim_create_augroup('jjsigns_buffer_' .. bufnr, { clear = true })
      local autocmds = {}

      table.insert(
        autocmds,
        api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
          group = group,
          buffer = bufnr,
          callback = function()
            update_buffer_debounced(bufnr)
          end,
        })
      )

      table.insert(
        autocmds,
        api.nvim_create_autocmd('BufWritePost', {
          group = group,
          buffer = bufnr,
          callback = function()
            -- After a write, the on-disk content matches the buffer but the
            -- base may have moved (e.g. user ran `jj squash` externally).
            -- Re-read base to stay correct, then re-render.
            reload_base(bufnr)
          end,
        })
      )

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

      buffer_state[bufnr] = {
        repo_root = repo_root,
        rel_path = rel_path,
        base_lines = nil,
        attached = true,
        autocmds = autocmds,
        request_id = 0,
      }

      reload_base(bufnr)
    end)
  end)
end

--- @param bufnr integer
--- @return JjBufferState?
function M.get_buffer_state(bufnr)
  return buffer_state[bufnr]
end

--- @param bufnr integer
--- @return boolean
function M.is_attached(bufnr)
  local state = buffer_state[bufnr]
  return state ~= nil and state.attached
end

function M.detach_all()
  for bufnr in pairs(buffer_state) do
    M.detach_buffer(bufnr)
  end
end

--- Force a fresh base read for every attached buffer (used by :JjSigns refresh
--- when the user has run jj operations from outside Neovim).
function M.refresh_all()
  for bufnr, state in pairs(buffer_state) do
    if api.nvim_buf_is_valid(bufnr) and state.attached then
      reload_base(bufnr)
    end
  end
end

--- Force a fresh base read for one buffer.
--- @param bufnr integer
function M.refresh_buffer(bufnr)
  if buffer_state[bufnr] and buffer_state[bufnr].attached then
    reload_base(bufnr)
  else
    M.attach_to_buffer(bufnr)
  end
end

return M

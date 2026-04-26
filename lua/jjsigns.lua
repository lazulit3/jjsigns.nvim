local api = vim.api
local async = require('jjsigns.async')
local config = require('jjsigns.config')
local attach = require('jjsigns.attach')

--- @class jjsigns.main
local M = {}

local function setup_attach()
  -- Auto-attach to buffers
  api.nvim_create_autocmd({ 'BufRead', 'BufNewFile', 'BufWritePost' }, {
    group = api.nvim_create_augroup('jjsigns_attach', { clear = true }),
    callback = function(args)
      if not config.config.enabled then
        return
      end

      local bufnr = args.buf
      if api.nvim_buf_get_name(bufnr) == '' then
        return
      end

      -- Don't attach to special buffers
      local buftype = vim.bo[bufnr].buftype
      if buftype ~= '' then
        return
      end

      async.run(function()
        attach.attach_to_buffer(bufnr)
      end)
    end,
  })

  -- Auto-attach to already loaded buffers
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(buf) and api.nvim_buf_get_name(buf) ~= '' then
      async.run(function()
        attach.attach_to_buffer(buf)
      end)
    end
  end
end

--- Setup JjSigns
--- @param opts table? Configuration options
function M.setup(opts)
  -- Check for jj executable
  if vim.fn.executable('jj') == 0 then
    vim.notify('jjsigns: jj executable not found in PATH', vim.log.levels.ERROR)
    return
  end

  config.setup(opts)

  -- Setup highlights
  require('jjsigns.highlight').setup()

  -- Setup auto-attach
  if config.config.attach.auto then
    setup_attach()
  end
end

--- Re-read base content for the current buffer (or all attached buffers).
--- Use after running jj operations outside Neovim that move the base revision.
local function refresh_command()
  local bufnr = api.nvim_get_current_buf()
  if attach.is_attached(bufnr) then
    attach.refresh_buffer(bufnr)
  else
    attach.refresh_all()
  end
end

--- Run a JjSigns command
--- @param params table Command parameters
function M.run_command(params)
  local args = params.args or ''
  local signs = require('jjsigns.signs')
  local commands = {
    setup = M.setup,
    toggle = M.toggle,
    disable = M.disable,
    enable = M.enable,
    refresh = refresh_command,
    toggle_signs = signs.toggle_signcolumn,
    toggle_numhl = signs.toggle_numhl,
    toggle_linehl = signs.toggle_linehl,
  }

  local cmd = args:match('^(%S+)')
  if commands[cmd] then
    commands[cmd]()
  else
    vim.notify('Unknown command: ' .. (cmd or ''), vim.log.levels.ERROR)
  end
end

--- Complete JjSigns commands
--- @param arglead string
--- @param line string
--- @return string[]
function M.complete(arglead, line)
  local commands = {
    'setup',
    'toggle',
    'disable',
    'enable',
    'refresh',
    'toggle_signs',
    'toggle_numhl',
    'toggle_linehl',
  }
  return vim.tbl_filter(function(cmd)
    return vim.startswith(cmd, arglead)
  end, commands)
end

--- Toggle JjSigns
function M.toggle()
  config.config.enabled = not config.config.enabled
  if config.config.enabled then
    setup_attach()
  else
    M.disable()
  end
end

--- Disable JjSigns
function M.disable()
  config.config.enabled = false
  require('jjsigns.signs').clear_all()
end

--- Enable JjSigns
function M.enable()
  config.config.enabled = true
  setup_attach()
end

return M

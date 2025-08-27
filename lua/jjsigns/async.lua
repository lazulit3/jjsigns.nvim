-- Simplified async implementation for jjsigns
local M = {}

--- Run a function asynchronously
--- @param fn function
function M.run(fn)
  vim.schedule(function()
    local ok, err = pcall(fn)
    if not ok then
      vim.notify('JjSigns async error: ' .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

return M

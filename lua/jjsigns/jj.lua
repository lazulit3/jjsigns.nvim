local M = {}

--- Execute a JJ command asynchronously.
--- @param args string[] Command arguments
--- @param opts table? Options. Recognized keys: cwd
--- @param callback fun(stdout: string[]?, stderr: string?, code: integer)
function M.command(args, opts, callback)
  opts = opts or {}

  local cmd = { 'jj', '--no-pager', '--color=never' }
  vim.list_extend(cmd, args)

  vim.system(cmd, { cwd = opts.cwd, text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        local lines = vim.split(result.stdout or '', '\n')
        if lines[#lines] == '' then
          table.remove(lines)
        end
        callback(lines, result.stderr, 0)
      else
        callback(nil, result.stderr, result.code)
      end
    end)
  end)
end

--- Get the repository root.
--- @param path string? Directory path (default: cwd)
--- @param callback fun(root: string?)
function M.get_repo_root(path, callback)
  M.command({ 'root' }, { cwd = path }, function(stdout, _, code)
    if code == 0 and stdout and stdout[1] then
      callback(vim.fs.normalize(stdout[1]))
    else
      callback(nil)
    end
  end)
end

--- Check if a file is tracked in the working copy.
--- @param filepath string File path relative to repo root
--- @param repo_root string Repository root
--- @param callback fun(tracked: boolean)
function M.is_file_tracked(filepath, repo_root, callback)
  M.command({ 'file', 'list', filepath }, { cwd = repo_root }, function(stdout, _, code)
    callback(code == 0 and stdout and #stdout > 0 or false)
  end)
end

--- Get file content at a specific revision.
--- @param filepath string File path relative to repo root
--- @param revision string? Revision (default: @-)
--- @param repo_root string Repository root
--- @param callback fun(lines: string[]?) nil if file does not exist at that revision
function M.get_file_content(filepath, revision, repo_root, callback)
  revision = revision or '@-'
  M.command(
    { 'file', 'show', '-r', revision, filepath },
    { cwd = repo_root },
    function(stdout, stderr, code)
      if code == 0 and stdout then
        callback(stdout)
      else
        if
          stderr
          and stderr ~= ''
          and not stderr:match('No such path')
          and not stderr:match('No file at')
        then
          vim.notify('jjsigns: error reading base content: ' .. stderr, vim.log.levels.WARN)
        end
        callback(nil)
      end
    end
  )
end

return M

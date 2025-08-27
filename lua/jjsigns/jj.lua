local M = {}

--- Execute a JJ command
--- @param args string[] Command arguments
--- @param opts table? Options (cwd, etc.)
--- @return string[]? stdout, string? stderr, integer? code
function M.command(args, opts)
  opts = opts or {}

  local cmd = { 'jj', '--no-pager', '--color=never' }
  vim.list_extend(cmd, args)

  local result = vim
    .system(cmd, {
      cwd = opts.cwd,
      text = true,
    })
    :wait()

  if result.code == 0 then
    local lines = vim.split(result.stdout or '', '\n')
    -- Remove empty last line if present
    if lines[#lines] == '' then
      table.remove(lines)
    end
    return lines, nil, 0
  else
    return nil, result.stderr, result.code
  end
end

--- Check if the current directory is a JJ repository
--- @param path string? Directory path to check (default: cwd)
--- @return boolean
function M.is_jj_repo(path)
  local result = vim
    .system({ 'jj', 'root' }, {
      cwd = path,
      text = true,
    })
    :wait()

  return result.code == 0
end

--- Get the repository root
--- @param path string? Directory path (default: cwd)
--- @return string? root_path
function M.get_repo_root(path)
  local stdout, _, code = M.command({ 'root' }, { cwd = path })
  if code == 0 and stdout and stdout[1] then
    return vim.fs.normalize(stdout[1])
  end
  return nil
end

--- Get the working copy ID
--- @param path string? Directory path (default: cwd)
--- @return string? working_copy_id
function M.get_working_copy_id(path)
  local stdout, _, code = M.command(
    { 'log', '-r', '@', '-T', 'change_id', '--no-graph' },
    { cwd = path }
  )
  if code == 0 and stdout and stdout[1] then
    return stdout[1]
  end
  return nil
end

--- Get file content at a specific revision
--- @param filepath string File path relative to repo root
--- @param revision string? Revision (default: @)
--- @param repo_root string? Repository root
--- @return string[]? lines
function M.get_file_content(filepath, revision, repo_root)
  revision = revision or '@'
  local stdout, stderr, code = M.command({ 'cat', '-r', revision, filepath }, { cwd = repo_root })

  if code == 0 and stdout then
    return stdout
  elseif stderr and not stderr:match('No such path') then
    vim.notify('JJ error getting file content: ' .. stderr, vim.log.levels.ERROR)
  end

  return nil
end

--- Get diff between two revisions for a file
--- @param filepath string File path relative to repo root
--- @param base_rev string? Base revision (default: @-)
--- @param target_rev string? Target revision (default: @)
--- @param repo_root string? Repository root
--- @return string[]? diff_lines
function M.get_file_diff(filepath, base_rev, target_rev, repo_root)
  base_rev = base_rev or '@-'
  target_rev = target_rev or '@'

  local stdout, stderr, code = M.command({
    'diff',
    '--git',
    '--context=0',
    '-r',
    base_rev .. '..' .. target_rev,
    '--',
    filepath,
  }, { cwd = repo_root })

  if code == 0 and stdout then
    return stdout
  elseif stderr and not stderr:match('No such path') then
    vim.notify('JJ error getting file diff: ' .. stderr, vim.log.levels.ERROR)
  end

  return nil
end

--- Check if a file is tracked in the working copy
--- @param filepath string File path relative to repo root
--- @param repo_root string? Repository root
--- @return boolean
function M.is_file_tracked(filepath, repo_root)
  local stdout, _, code = M.command({ 'file', 'list', filepath }, { cwd = repo_root })
  return code == 0 and stdout and #stdout > 0
end

return M

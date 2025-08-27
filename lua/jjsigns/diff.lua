local M = {}

--- @class JjHunk
--- @field type 'add' | 'delete' | 'change'
--- @field start_line integer Starting line number (1-indexed)
--- @field end_line integer Ending line number (1-indexed)
--- @field old_start integer Starting line in old file
--- @field old_count integer Number of lines in old file
--- @field new_start integer Starting line in new file
--- @field new_count integer Number of lines in new file

--- Parse a git-style diff to extract hunks
--- @param diff_lines string[] Lines from diff output
--- @return JjHunk[]
function M.parse_diff(diff_lines)
  local hunks = {}

  for _, line in ipairs(diff_lines) do
    -- Look for hunk headers: @@ -old_start,old_count +new_start,new_count @@
    local old_start, old_count, new_start, new_count =
      line:match('^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@')

    if old_start and new_start then
      old_start = tonumber(old_start)
      new_start = tonumber(new_start)
      old_count = old_count ~= '' and tonumber(old_count) or 1
      new_count = new_count ~= '' and tonumber(new_count) or 1

      local hunk_type
      if old_count == 0 then
        hunk_type = 'add'
      elseif new_count == 0 then
        hunk_type = 'delete'
      else
        hunk_type = 'change'
      end

      local hunk = {
        type = hunk_type,
        old_start = old_start,
        old_count = old_count,
        new_start = new_start,
        new_count = new_count,
        start_line = new_start,
        end_line = new_start + math.max(0, new_count - 1),
      }

      table.insert(hunks, hunk)
    end
  end

  return hunks
end

--- Convert hunks to signs data
--- @param hunks JjHunk[]
--- @return table[] Array of sign data {line: integer, type: string}
function M.hunks_to_signs(hunks)
  local signs = {}

  for _, hunk in ipairs(hunks) do
    if hunk.type == 'add' then
      -- Add signs for all added lines
      for line = hunk.start_line, hunk.end_line do
        table.insert(signs, { line = line, type = 'add' })
      end
    elseif hunk.type == 'delete' then
      -- For deleted lines, show a sign at the line where deletion occurred
      local sign_type = hunk.new_start == 1 and 'topdelete' or 'delete'
      table.insert(signs, { line = hunk.new_start, type = sign_type })
    elseif hunk.type == 'change' then
      -- For changed lines, determine if it's pure change or change with delete
      if hunk.old_count == hunk.new_count then
        -- Pure change
        for line = hunk.start_line, hunk.end_line do
          table.insert(signs, { line = line, type = 'change' })
        end
      elseif hunk.old_count > hunk.new_count then
        -- Change with some deletions
        for line = hunk.start_line, hunk.end_line do
          table.insert(signs, { line = line, type = 'changedelete' })
        end
      else
        -- Change with some additions
        for line = hunk.start_line, hunk.start_line + hunk.old_count - 1 do
          table.insert(signs, { line = line, type = 'change' })
        end
        for line = hunk.start_line + hunk.old_count, hunk.end_line do
          table.insert(signs, { line = line, type = 'add' })
        end
      end
    end
  end

  return signs
end

--- Get diff hunks for a file
--- @param filepath string Absolute file path
--- @param repo_root string Repository root path
--- @param base_rev string? Base revision (default: @-)
--- @return JjHunk[]
function M.get_file_hunks(filepath, repo_root, base_rev)
  local jj = require('jjsigns.jj')

  -- Convert absolute path to relative path
  local rel_path = filepath
  if vim.startswith(filepath, repo_root) then
    rel_path = filepath:sub(#repo_root + 2) -- +2 to skip the separator
  end

  local diff_lines = jj.get_file_diff(rel_path, base_rev, '@', repo_root)
  if not diff_lines then
    return {}
  end

  return M.parse_diff(diff_lines)
end

return M

local M = {}

--- @class JjHunk
--- @field type 'add' | 'delete' | 'change'
--- @field start_line integer Starting line number (1-indexed) in current file
--- @field end_line integer Ending line number (1-indexed) in current file
--- @field old_start integer Starting line in base file
--- @field old_count integer Number of lines in base file
--- @field new_start integer Starting line in current file
--- @field new_count integer Number of lines in current file

--- Compute hunks between base and current line arrays using vim.diff.
--- @param base_lines string[]
--- @param current_lines string[]
--- @return JjHunk[]
function M.compute_hunks(base_lines, current_lines)
  local base_text = table.concat(base_lines, '\n')
  local current_text = table.concat(current_lines, '\n')

  -- vim.diff returns a list of {old_start, old_count, new_start, new_count}.
  -- A *_count of 0 means the hunk anchors at the line *after* (old) or *before*
  -- (new) the given start. vim.diff handles the empty-side semantics for us.
  local raw = vim.diff(base_text, current_text, {
    result_type = 'indices',
    algorithm = 'minimal',
  })

  if type(raw) ~= 'table' then
    return {}
  end

  local hunks = {}
  for _, h in ipairs(raw) do
    local old_start, old_count, new_start, new_count = h[1], h[2], h[3], h[4]

    local hunk_type
    if old_count == 0 then
      hunk_type = 'add'
    elseif new_count == 0 then
      hunk_type = 'delete'
    else
      hunk_type = 'change'
    end

    table.insert(hunks, {
      type = hunk_type,
      old_start = old_start,
      old_count = old_count,
      new_start = new_start,
      new_count = new_count,
      start_line = new_start,
      end_line = new_start + math.max(0, new_count - 1),
    })
  end

  return hunks
end

--- Convert hunks to per-line sign data.
--- @param hunks JjHunk[]
--- @return table[] Array of sign data {line: integer, type: string}
function M.hunks_to_signs(hunks)
  local signs = {}

  for _, hunk in ipairs(hunks) do
    if hunk.type == 'add' then
      for line = hunk.start_line, hunk.end_line do
        table.insert(signs, { line = line, type = 'add' })
      end
    elseif hunk.type == 'delete' then
      local sign_type = hunk.new_start == 0 and 'topdelete' or 'delete'
      local anchor = math.max(1, hunk.new_start)
      table.insert(signs, { line = anchor, type = sign_type })
    elseif hunk.type == 'change' then
      if hunk.old_count == hunk.new_count then
        for line = hunk.start_line, hunk.end_line do
          table.insert(signs, { line = line, type = 'change' })
        end
      elseif hunk.old_count > hunk.new_count then
        for line = hunk.start_line, hunk.end_line do
          table.insert(signs, { line = line, type = 'changedelete' })
        end
      else
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

return M

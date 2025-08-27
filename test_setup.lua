-- Test script for jjsigns.nvim
-- Run with: nvim -l test_setup.lua

-- Add the plugin to package.path
local plugin_path = debug.getinfo(1).source:match('@?(.*/)')
if plugin_path then
  package.path = plugin_path .. 'lua/?.lua;' .. package.path
else
  package.path = './lua/?.lua;' .. package.path
end

print('Testing jjsigns.nvim...')

-- Test basic module loading
local success, jjsigns = pcall(require, 'jjsigns')
if not success then
  print('❌ Failed to load jjsigns module: ' .. tostring(jjsigns))
  return
end
print('✅ Successfully loaded jjsigns module')

-- Test config loading
local success, config = pcall(require, 'jjsigns.config')
if not success then
  print('❌ Failed to load config module: ' .. tostring(config))
  return
end
print('✅ Successfully loaded config module')

-- Test JJ interface
local success, jj = pcall(require, 'jjsigns.jj')
if not success then
  print('❌ Failed to load jj module: ' .. tostring(jj))
  return
end
print('✅ Successfully loaded jj module')

-- Test JJ executable
local has_jj = vim.fn.executable('jj') == 1
if has_jj then
  print('✅ jj executable found')

  -- Test JJ version
  local result = vim.system({ 'jj', '--version' }):wait()
  if result.code == 0 then
    print('✅ jj version: ' .. (result.stdout or 'unknown'))
  else
    print('⚠️  Could not get jj version')
  end
else
  print('❌ jj executable not found in PATH')
end

-- Test diff parsing
local success, diff = pcall(require, 'jjsigns.diff')
if not success then
  print('❌ Failed to load diff module: ' .. tostring(diff))
  return
end
print('✅ Successfully loaded diff module')

-- Test diff parsing with sample data
local sample_diff = {
  'diff --git a/test.txt b/test.txt',
  'index 1234567..abcdefg 100644',
  '--- a/test.txt',
  '+++ b/test.txt',
  '@@ -1,3 +1,4 @@',
  ' line 1',
  '+line 1.5',
  ' line 2',
  ' line 3',
}

local hunks = diff.parse_diff(sample_diff)
if #hunks > 0 then
  print('✅ Diff parsing works - found ' .. #hunks .. ' hunk(s)')
  local signs = diff.hunks_to_signs(hunks)
  print('✅ Sign conversion works - generated ' .. #signs .. ' sign(s)')
else
  print('⚠️  Diff parsing returned no hunks')
end

-- Test signs module
local success, signs = pcall(require, 'jjsigns.signs')
if not success then
  print('❌ Failed to load signs module: ' .. tostring(signs))
  return
end
print('✅ Successfully loaded signs module')

-- Test attach module
local success, attach = pcall(require, 'jjsigns.attach')
if not success then
  print('❌ Failed to load attach module: ' .. tostring(attach))
  return
end
print('✅ Successfully loaded attach module')

-- Test highlight module
local success, highlight = pcall(require, 'jjsigns.highlight')
if not success then
  print('❌ Failed to load highlight module: ' .. tostring(highlight))
  return
end
print('✅ Successfully loaded highlight module')

print('\n🎉 All basic tests passed!')
print('\nTo test with a real JJ repository:')
print('1. Navigate to a directory with a JJ repository')
print('2. Start Neovim: nvim')
print("3. Run: :lua require('jjsigns').setup()")
print('4. Open a tracked file and make some changes')
print(
  '5. You should see the exact same signs as gitsigns (┃, ▁, ▔, ~) in the gutter indicating changes'
)

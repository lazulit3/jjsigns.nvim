if vim.g.loaded_jjsigns or vim.version().minor < 9 then
  return
end
vim.g.loaded_jjsigns = true

vim.api.nvim_create_user_command('JjSigns', function(params)
  require('jjsigns').run_command(params)
end, {
  nargs = '*',
  range = true,
  complete = function(arglead, line)
    return require('jjsigns').complete(arglead, line)
  end,
})

local buffer = require('mado-scratch-buffer.buffer')

vim.api.nvim_create_user_command('MadoScratchBufferOpen', function(opts)
  buffer.open(false, unpack(opts.fargs))
end, {
  nargs = '*',
  desc = 'Open a temporary mado scratch buffer'
})

vim.api.nvim_create_user_command('MadoScratchBufferOpenFile', function(opts)
  buffer.open_file(false, unpack(opts.fargs))
end, {
  nargs = '*',
  desc = 'Open a persistent mado scratch buffer'
})

vim.api.nvim_create_user_command('MadoScratchBufferOpenNext', function(opts)
  buffer.open(true, unpack(opts.fargs))
end, {
  nargs = '*',
  desc = 'Open a new temporary mado scratch buffer'
})

vim.api.nvim_create_user_command('MadoScratchBufferOpenFileNext', function(opts)
  buffer.open_file(true, unpack(opts.fargs))
end, {
  nargs = '*',
  desc = 'Open a new persistent mado scratch buffer'
})

vim.api.nvim_create_user_command('MadoScratchBufferClean', function()
  buffer.clean()
end, {
  desc = 'Clean up all mado scratch buffers and files'
})

-- Auto-setup with default configuration if not already configured
if not pcall(require('mado-scratch-buffer').get_config) then
  require('mado-scratch-buffer').setup()
end

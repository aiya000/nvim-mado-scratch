-- Plugin guard
if vim.g.loaded_mado_scratch_buffer then
  return
end

-- Ensure we have Neovim
if vim.fn.has('nvim-0.8') == 0 then
  vim.api.nvim_err_writeln('mado-scratch-buffer.nvim requires Neovim 0.8+')
  return
end

local buffer = require('scratch-buffer.buffer')

-- Define commands
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
if not require('scratch-buffer').config or vim.tbl_isempty(require('scratch-buffer').config) then
  require('scratch-buffer').setup()
end

-- Mark as loaded
vim.g.loaded_mado_scratch_buffer = true
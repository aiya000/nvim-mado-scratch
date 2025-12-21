local M = {}

function M.save_file_buffer_if_enabled()
  local config = require('mado-scratch-buffer').get_config()
  if config.auto_save_file_buffer and vim.bo.buftype ~= 'nofile' then
    vim.cmd.write({
      mods = { silent = true },
      bang = true,
    })
  end
end

function M.hide_buffer_if_enabled()
  local config = require('mado-scratch-buffer').get_config()

  if vim.bo.buftype == 'nofile' and config.auto_hide_buffer.when_tmp_buffer then
    vim.cmd.quit()
    return
  end

  if config.auto_hide_buffer.when_file_buffer then
    vim.cmd.quit()
    return
  end
end

function M.setup_autocmds()
  local config = require('mado-scratch-buffer').get_config()
  local augroup = vim.api.nvim_create_augroup('MadoScratchBuffer', { clear = true })

  -- Save on InsertLeave
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = augroup,
    pattern = config.file_pattern.when_file_buffer:gsub('%%d', '*'),
    callback = M.save_file_buffer_if_enabled,
  })

  -- Save before buffer is destroyed
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout', 'BufUnload' }, {
    group = augroup,
    pattern = config.file_pattern.when_file_buffer:gsub('%%d', '*'),
    callback = M.save_file_buffer_if_enabled,
  })

  -- Hide buffer when leaving window
  vim.api.nvim_create_autocmd('WinLeave', {
    group = augroup,
    pattern = {
      config.file_pattern.when_tmp_buffer:gsub('%%d', '*'),
      config.file_pattern.when_file_buffer:gsub('%%d', '*'),
    },
    callback = M.hide_buffer_if_enabled,
  })
end

return M

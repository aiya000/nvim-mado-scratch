local M = {}

---Saves file buffer if enabled
function M.save_file_buffer_if_enabled()
  local config = require('mado-scratch-buffer').config
  local buftype = vim.bo.buftype

  if config.auto_save_file_buffer and buftype ~= 'nofile' then
    vim.cmd.write({ mods = { silent = true } })
  end
end

---Hides buffer if enabled
function M.hide_buffer_if_enabled()
  local config = require('mado-scratch-buffer').config
  local buftype = vim.bo.buftype

  if buftype == 'nofile' and config.auto_hide_buffer.when_tmp_buffer then
    vim.cmd.quit()
    return
  end

  if config.auto_hide_buffer.when_file_buffer then
    vim.cmd.quit()
    return
  end
end

---Setups autocmds for scratch buffer
function M.setup_autocmds()
  local config = require('mado-scratch-buffer').config

  local augroup = vim.api.nvim_create_augroup('MadoScratchBuffer', { clear = true })
  vim.api.nvim_create_autocmd('TextChanged', {
    group = augroup,
    pattern = config.file_pattern.when_file_buffer:gsub('%%d', '*'),
    callback = M.save_file_buffer_if_enabled,
  })

  vim.api.nvim_create_autocmd('WinLeave', {
    group = augroup,
    pattern = config.file_pattern.when_tmp_buffer:gsub('%%d', '*'),
    callback = M.hide_buffer_if_enabled,
  })

  vim.api.nvim_create_autocmd('WinLeave', {
    group = augroup,
    pattern = config.file_pattern.when_file_buffer:gsub('%%d', '*'),
    callback = M.hide_buffer_if_enabled,
  })
end

return M

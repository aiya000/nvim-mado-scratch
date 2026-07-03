local M = {}

function M.save_file_buffer_if_enabled()
  local config = require('mado-scratch').get_config()
  if config.auto_save_file_buffer and vim.bo.buftype ~= 'nofile' then
    -- Catch E32 (No file name) error
    -- (Occurs when a buffer before opening mado-scratch buffer has no name)
    local success, err = pcall(vim.cmd.write, {
      mods = { silent = true },
      bang = true,
    })
    if not success and not (err and string.match(err, 'E32:')) then
      error(err)
    end
  end
end

function M.trigger_pre_closed_autocmd()
  vim.cmd('doautocmd User MadoScratchBufferPreClosed')
end

function M.trigger_closed_autocmd()
  vim.cmd('doautocmd User MadoScratchBufferClosed')
end

function M.trigger_window_pre_opened_autocmd()
  vim.cmd('doautocmd User MadoScratchWindowPreOpened')
end

function M.trigger_window_opened_autocmd()
  vim.cmd('doautocmd User MadoScratchWindowOpened')
end

function M.trigger_window_pre_closed_autocmd()
  vim.cmd('doautocmd User MadoScratchWindowPreClosed')
end

function M.trigger_window_closed_autocmd()
  vim.cmd('doautocmd User MadoScratchWindowClosed')
end

---Registers a one-shot WinClosed autocmd for the given window ID.
---Fires MadoScratchWindowPreClosed then MadoScratchWindowClosed when the window closes.
---@param winid integer
function M.register_window_close_autocmd(winid)
  local augroup = vim.api.nvim_create_augroup('MadoScratch', { clear = false })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = augroup,
    pattern = tostring(winid),
    once = true,
    nested = true,
    callback = function()
      M.trigger_window_pre_closed_autocmd()
      vim.schedule(M.trigger_window_closed_autocmd)
    end,
  })
end

function M.hide_buffer_if_enabled()
  local config = require('mado-scratch').get_config()

  -- Always close float windows on WinLeave, since Neovim does not allow
  -- splitting float windows (E5601). Closing the float here allows commands
  -- like :vsp to operate on the underlying regular window without error.
  local win_config = vim.api.nvim_win_get_config(0)
  if win_config.relative ~= '' then
    pcall(vim.cmd.quit)
    return
  end

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
  local config = require('mado-scratch').get_config()
  local augroup = vim.api.nvim_create_augroup('MadoScratch', { clear = true })

  local file_buffer_pattern = config.file_pattern.when_file_buffer:gsub('%%d', '*')
  local tmp_buffer_pattern = config.file_pattern.when_tmp_buffer:gsub('%%d', '*')

  -- Trigger PreClosed before buffer is deleted
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout', 'BufUnload' }, {
    group = augroup,
    pattern = {
      tmp_buffer_pattern,
      file_buffer_pattern,
    },
    callback = M.trigger_pre_closed_autocmd,
  })

  -- Trigger Closed after buffer is deleted
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout', 'BufUnload' }, {
    group = augroup,
    pattern = {
      tmp_buffer_pattern,
      file_buffer_pattern,
    },
    nested = true,
    callback = function()
      -- Use vim.schedule to ensure this runs after the buffer is actually deleted
      vim.schedule(M.trigger_closed_autocmd)
    end,
  })

  -- Save on InsertLeave and a buffer is closed
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufDelete', 'BufWipeout', 'BufUnload' }, {
    group = augroup,
    pattern = file_buffer_pattern,
    callback = M.save_file_buffer_if_enabled,
  })

  -- Hide buffer when leaving window
  vim.api.nvim_create_autocmd('WinLeave', {
    group = augroup,
    pattern = {
      tmp_buffer_pattern,
      file_buffer_pattern,
    },
    callback = M.hide_buffer_if_enabled,
  })
end

return M

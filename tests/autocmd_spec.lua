local test_cases = {
  { cmd = 'MadoScratchOpen', method = 'sp', desc = ':MadoScratchOpen md sp' },
  { cmd = 'MadoScratchOpen', method = 'vsp', desc = ':MadoScratchOpen md vsp' },
  { cmd = 'MadoScratchOpen', method = 'tabnew', desc = ':MadoScratchOpen md tabnew' },
  { cmd = 'MadoScratchOpen', method = 'float-fixed', desc = ':MadoScratchOpen md float-fixed' },
  { cmd = 'MadoScratchOpen', method = 'float-aspect', desc = ':MadoScratchOpen md float-aspect' },
  { cmd = 'MadoScratchOpenFile', method = 'sp', desc = ':MadoScratchOpenFile md sp' },
  { cmd = 'MadoScratchOpenFile', method = 'vsp', desc = ':MadoScratchOpenFile md vsp' },
  { cmd = 'MadoScratchOpenFile', method = 'tabnew', desc = ':MadoScratchOpenFile md tabnew' },
  { cmd = 'MadoScratchOpenFile', method = 'float-fixed', desc = ':MadoScratchOpenFile md float-fixed' },
  { cmd = 'MadoScratchOpenFile', method = 'float-aspect', desc = ':MadoScratchOpenFile md float-aspect' },
}

describe('mado-scratch autocmds', function()
  before_each(function()
    -- Disable swap files to avoid E325 errors when tests run in parallel
    vim.o.swapfile = false

    require('mado-scratch').setup({
      file_pattern = {
        when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
        when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
      },
      default_file_ext = 'md',
      default_open_method = { method = 'sp', height = 15 },
      auto_save_file_buffer = false,
      use_default_keymappings = false,
      auto_hide_buffer = {
        when_tmp_buffer = false,
        when_file_buffer = false,
      },
    })

    vim.cmd([[
      MadoScratchClean
      new
      only
    ]])
  end)

  after_each(function()
    -- Wait a bit for any pending async operations to complete
    vim.wait(50, function() return false end, 10)
    
    -- Clean up any remaining User autocmds that might not have fired
    pcall(vim.cmd, 'autocmd! User MadoScratchBufferOpened')
    pcall(vim.cmd, 'autocmd! User MadoScratchBufferPreOpened')
    pcall(vim.cmd, 'autocmd! User MadoScratchBufferClosed')
    pcall(vim.cmd, 'autocmd! User MadoScratchBufferPreClosed')
    pcall(vim.cmd, 'autocmd! User MadoScratchWindowOpened')
    pcall(vim.cmd, 'autocmd! User MadoScratchWindowPreOpened')
    pcall(vim.cmd, 'autocmd! User MadoScratchWindowClosed')
    pcall(vim.cmd, 'autocmd! User MadoScratchWindowPreClosed')
    
    -- Collect file paths before cleaning up buffers
    local files_to_delete = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match('scratch%-tmp') or name:match('scratch%-file') then
          if name ~= '' and vim.fn.filereadable(name) == 1 then
            table.insert(files_to_delete, name)
          end
        end
      end
    end
    
    -- Clean up buffers
    vim.cmd([[
      MadoScratchClean
      only
    ]])
    
    -- Force cleanup of any remaining scratch buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match('scratch%-tmp') or name:match('scratch%-file') then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
    
    -- Delete any remaining files on disk that MadoScratchClean might have missed
    for _, file in ipairs(files_to_delete) do
      if vim.fn.filereadable(file) == 1 then
        pcall(vim.fn.delete, file)
      end
    end
    
    -- Wait for buffer and file cleanup to complete
    vim.wait(100, function() return false end, 10)
  end)

  describe('User autocmd MadoScratchBufferOpened', function()
    for _, test_case in ipairs(test_cases) do
      it('should trigger for ' .. test_case.desc, function()
        local triggered = false
        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchBufferOpened',
          callback = function()
            triggered = true
          end,
          once = true,
        })

        vim.cmd(test_case.cmd .. ' md ' .. test_case.method)
        assert.is_true(triggered)
      end)
    end
  end)

  describe('User autocmd MadoScratchBufferPreOpened', function()
    for _, test_case in ipairs(test_cases) do
      it('should trigger for ' .. test_case.desc, function()
        local pre_opened_triggered = false
        local opened_triggered = false
        local order_correct = false

        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchBufferPreOpened',
          callback = function()
            pre_opened_triggered = true
            if not opened_triggered then
              order_correct = true
            end
          end,
          once = true,
        })

        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchBufferOpened',
          callback = function()
            opened_triggered = true
          end,
          once = true,
        })

        vim.cmd(test_case.cmd .. ' md ' .. test_case.method)

        assert.is_true(pre_opened_triggered)
        assert.is_true(opened_triggered)
        assert.is_true(order_correct)
      end)
    end
  end)

  describe('User autocmd MadoScratchBufferClosed', function()
    for _, test_case in ipairs(test_cases) do
      it('should trigger for ' .. test_case.desc, function()
        local triggered = false
        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchBufferClosed',
          callback = function()
            triggered = true
          end,
          once = true,
        })

        vim.cmd(test_case.cmd .. ' md ' .. test_case.method)
        local bufnr = vim.fn.bufnr('%')
        vim.cmd('bdelete! ' .. bufnr)

        -- Wait for scheduled callback to complete
        -- Use vim.wait with a condition to ensure the callback has executed
        local success = vim.wait(1000, function()
          return triggered
        end, 10)
        
        -- If wait timed out, process events one more time
        if not success then
          vim.cmd('doautocmd User')
          vim.wait(100, function() return triggered end, 10)
        end

        assert.is_true(triggered)
      end)
    end
  end)

  describe('User autocmd MadoScratchBufferPreClosed', function()
    for _, test_case in ipairs(test_cases) do
      it('should trigger for ' .. test_case.desc, function()
        local pre_closed_triggered = false
        local closed_triggered = false
        local order_correct = false

        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchBufferPreClosed',
          callback = function()
            pre_closed_triggered = true
            if not closed_triggered then
              order_correct = true
            end
          end,
          once = true,
        })

        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchBufferClosed',
          callback = function()
            closed_triggered = true
          end,
          once = true,
        })

        vim.cmd(test_case.cmd .. ' md ' .. test_case.method)
        local bufnr = vim.fn.bufnr('%')
        vim.cmd('bdelete! ' .. bufnr)

        -- Wait for scheduled callback to complete
        -- Use vim.wait with a condition to ensure both callbacks have executed
        local success = vim.wait(1000, function()
          return pre_closed_triggered and closed_triggered
        end, 10)
        
        -- If wait timed out, process events one more time
        if not success then
          vim.cmd('doautocmd User')
          vim.wait(100, function() return pre_closed_triggered and closed_triggered end, 10)
        end

        assert.is_true(pre_closed_triggered)
        assert.is_true(closed_triggered)
        assert.is_true(order_correct)
      end)
    end
  end)

  describe('User autocmd MadoScratchWindowOpened', function()
    for _, test_case in ipairs(test_cases) do
      it('should trigger for ' .. test_case.desc, function()
        local triggered = false
        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchWindowOpened',
          callback = function()
            triggered = true
          end,
          once = true,
        })

        vim.cmd(test_case.cmd .. ' md ' .. test_case.method)
        assert.is_true(triggered)
      end)
    end
  end)

  describe('User autocmd MadoScratchWindowPreOpened', function()
    for _, test_case in ipairs(test_cases) do
      it('should trigger for ' .. test_case.desc, function()
        local pre_opened_triggered = false
        local opened_triggered = false
        local order_correct = false

        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchWindowPreOpened',
          callback = function()
            pre_opened_triggered = true
            if not opened_triggered then
              order_correct = true
            end
          end,
          once = true,
        })

        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchWindowOpened',
          callback = function()
            opened_triggered = true
          end,
          once = true,
        })

        vim.cmd(test_case.cmd .. ' md ' .. test_case.method)

        assert.is_true(pre_opened_triggered)
        assert.is_true(opened_triggered)
        assert.is_true(order_correct)
      end)
    end
  end)

  describe('User autocmd MadoScratchWindowClosed', function()
    for _, test_case in ipairs(test_cases) do
      it('should trigger for ' .. test_case.desc, function()
        local triggered = false
        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchWindowClosed',
          callback = function()
            triggered = true
          end,
          once = true,
        })

        vim.cmd(test_case.cmd .. ' md ' .. test_case.method)
        local winid = vim.api.nvim_get_current_win()
        vim.api.nvim_win_close(winid, true)

        -- Wait for scheduled callback to complete
        -- Use vim.wait with a condition to ensure the callback has executed
        local success = vim.wait(1000, function()
          return triggered
        end, 10)

        -- If wait timed out, process events one more time
        if not success then
          vim.cmd('doautocmd User')
          vim.wait(100, function() return triggered end, 10)
        end
        assert.is_true(triggered)
      end)
    end
  end)

  describe('User autocmd MadoScratchWindowPreClosed', function()
    for _, test_case in ipairs(test_cases) do
      it('should trigger for ' .. test_case.desc, function()
        local pre_closed_triggered = false
        local closed_triggered = false
        local order_correct = false

        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchWindowPreClosed',
          callback = function()
            pre_closed_triggered = true
            if not closed_triggered then
              order_correct = true
            end
          end,
          once = true,
        })

        vim.api.nvim_create_autocmd('User', {
          pattern = 'MadoScratchWindowClosed',
          callback = function()
            closed_triggered = true
          end,
          once = true,
        })

        vim.cmd(test_case.cmd .. ' md ' .. test_case.method)
        local winid = vim.api.nvim_get_current_win()
        vim.api.nvim_win_close(winid, true)

        -- Wait for scheduled callback to complete
        -- Use vim.wait with a condition to ensure both callbacks have executed
        local success = vim.wait(1000, function()
          return pre_closed_triggered and closed_triggered
        end, 10)

        -- If wait timed out, process events one more time
        if not success then
          vim.cmd('doautocmd User')
          vim.wait(100, function() return pre_closed_triggered and closed_triggered end, 10)
        end
        assert.is_true(pre_closed_triggered)
        assert.is_true(closed_triggered)
        assert.is_true(order_correct)
      end)
    end
  end)
end)

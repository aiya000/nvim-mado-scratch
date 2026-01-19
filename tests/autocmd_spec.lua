describe('mado-scratch autocmds', function()
  before_each(function()
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
    vim.cmd([[
      MadoScratchClean
      only
    ]])
  end)

  describe('User autocmd MadoScratchBufferOpened', function()
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
        vim.wait(1000, function()
          return triggered
        end, 10)

        assert.is_true(triggered)
      end)
    end
  end)

  describe('User autocmd MadoScratchBufferPreClosed', function()
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
        vim.wait(1000, function()
          return pre_closed_triggered and closed_triggered
        end, 10)

        assert.is_true(pre_closed_triggered)
        assert.is_true(closed_triggered)
        assert.is_true(order_correct)
      end)
    end
  end)
end)

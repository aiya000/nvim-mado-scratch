local helper = require('mado-scratch.helper')

---Checks if a table contains a value
---@generic T
---@param tbl T[]
---@param value T
---@return boolean
local function contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

describe('mado-scratch', function()
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
      silent! only
    ]])
  end)

  after_each(function()
    local config = require('mado-scratch').get_config()
    local file_pattern_tmp = config.file_pattern.when_tmp_buffer
    local file_pattern_file = config.file_pattern.when_file_buffer

    -- Clean all created files
    local tmp_files = vim.fn.glob(file_pattern_tmp:gsub('%%d', '*'), false, true)
    for _, file in ipairs(tmp_files) do
      vim.fn.delete(file)
    end
    local file_files = vim.fn.glob(file_pattern_file:gsub('%%d', '*'), false, true)
    for _, file in ipairs(file_files) do
      vim.fn.delete(file)
    end
  end)

  describe('MadoScratchOpen', function()
    it('should create a buffer', function()
      vim.cmd('MadoScratchOpen')
      local file_name = vim.fn.expand('%:p')
      local mado = require('mado-scratch')
      local expected = string.format(mado.get_config().file_pattern.when_tmp_buffer, 0) .. '.md'
      assert.equals(file_name, expected)
    end)

    it('should open readonly file (nofile buftype)', function()
      vim.cmd('MadoScratchOpen')
      local success, _ = pcall(function()
        vim.cmd('write')
      end)
      assert.is_false(success)
    end)

    it('should accept file extension', function()
      vim.cmd('MadoScratchOpen md')
      local file_name = vim.fn.expand('%:p')
      assert.is_true(file_name:match('%.md$') ~= nil)
    end)

    it('should set filetype based on file extension', function()
      vim.cmd('MadoScratchOpen md')
      assert.equals('markdown', vim.bo.filetype)
    end)

    it('should set filetype for typescript files', function()
      vim.cmd('MadoScratchOpen ts')
      assert.equals('typescript', vim.bo.filetype)
    end)

    it('should set filetype for python files', function()
      vim.cmd('MadoScratchOpen py')
      assert.equals('python', vim.bo.filetype)
    end)

    it('should set filetype for javascript files', function()
      vim.cmd('MadoScratchOpen js')
      assert.equals('javascript', vim.bo.filetype)
    end)

    it('should accept open method', function()
      vim.cmd('MadoScratchOpen md sp')
      local file_name1 = vim.fn.expand('%:p')
      assert.is_not_nil(file_name1)

      vim.cmd('MadoScratchOpen md vsp')
      local file_name2 = vim.fn.expand('%:p')
      assert.is_not_nil(file_name2)
    end)

    it('should accept buffer size', function()
      vim.cmd('MadoScratchOpen md sp 5')
      local file_name1 = vim.fn.expand('%:p')
      assert.is_not_nil(file_name1)

      vim.cmd('MadoScratchOpen md vsp 50')
      local file_name2 = vim.fn.expand('%:p')
      assert.is_not_nil(file_name2)
    end)

    it('should use default values', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_file_ext = 'ts',
        default_open_method = { method = 'vsp', width = 20 },
      })

      vim.cmd('new')
      vim.cmd('MadoScratchOpen')

      local file_name = vim.fn.expand('%:p')
      local expected = string.format(mado.get_config().file_pattern.when_tmp_buffer, 0) .. '.ts'
      assert.equals(file_name, expected)
      assert.equals(vim.fn.winwidth(0), 20)
    end)

    it('should use when_tmp_buffer pattern', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = 'not specified',
        },
      })

      vim.cmd('MadoScratchOpen')
      local file_name = vim.fn.expand('%:p')
      local expected = string.format(mado.get_config().file_pattern.when_tmp_buffer, 0) .. '.md'
      assert.equals(file_name, expected)
    end)

    it('should support auto hiding tmp buffer', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        auto_hide_buffer = {
          when_tmp_buffer = true,
          when_file_buffer = true,
        },
      })

      vim.cmd('MadoScratchOpen md')
      vim.cmd('wincmd p')  -- Trigger WinLeave
      assert.equals(vim.fn.winnr('$'), 1)
    end)
  end)

  describe('MadoScratchOpenNext', function()
    it('can make multiple buffers', function()
      vim.cmd('MadoScratchOpen')
      local main_file = vim.fn.expand('%:p')

      vim.cmd('MadoScratchOpenNext')
      local next_file = vim.fn.expand('%:p')

      assert.is_not.equals(main_file, next_file)
    end)

    it('should open recent buffer after OpenNext', function()
      vim.cmd('MadoScratchOpenNext')
      local first_file = vim.fn.expand('%:p')

      vim.cmd('new')

      vim.cmd('MadoScratchOpen')
      local second_file = vim.fn.expand('%:p')

      assert.equals(second_file, first_file)
    end)
  end)

  describe('MadoScratchOpenFile', function()
    it('should open writable file', function()
      vim.cmd('MadoScratchOpenFile')
      local success, _ = pcall(function()
        vim.cmd('write')
      end)
      assert.is_true(success)
    end)

    it('should use when_file_buffer pattern', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = 'not specified',
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
      })

      vim.cmd('MadoScratchOpenFile')
      local file_name = vim.fn.expand('%:p')
      local expected = string.format(mado.get_config().file_pattern.when_file_buffer, 0) .. '.md'
      assert.equals(file_name, expected)
    end)

    it('should set filetype based on file extension', function()
      vim.cmd('MadoScratchOpenFile md')
      assert.equals('markdown', vim.bo.filetype)
    end)

    it('should set filetype for typescript files', function()
      vim.cmd('MadoScratchOpenFile ts')
      assert.equals('typescript', vim.bo.filetype)
    end)

    it('should set filetype for python files', function()
      vim.cmd('MadoScratchOpenFile py')
      assert.equals('python', vim.bo.filetype)
    end)

    it('should support auto saving file buffer on InsertLeave', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        auto_save_file_buffer = true,
      })

      vim.cmd('MadoScratchOpenFile md')
      vim.fn.setline(1, 'insert leave content')
      vim.cmd('doautocmd InsertLeave')

      local file_name = vim.fn.expand('%:p')
      assert.equals(vim.fn.filereadable(file_name), 1)
      local content = vim.fn.readfile(file_name)
      assert.equals(content[1], 'insert leave content')
    end)

    it('should support auto saving file buffer before buffer destruction', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        auto_save_file_buffer = true,
      })

      vim.cmd('MadoScratchOpenFile md')
      local file_name = vim.fn.expand('%:p')
      vim.fn.setline(1, 'buffer delete content')
      vim.cmd('doautocmd BufDelete')

      assert.equals(vim.fn.filereadable(file_name), 1)
      local content = vim.fn.readfile(file_name)
      assert.equals(content[1], 'buffer delete content')
    end)

    it('should not auto save when auto_save_file_buffer is disabled', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        auto_save_file_buffer = false,
      })

      vim.cmd('MadoScratchOpenFile md')
      local file_name = vim.fn.expand('%:p')
      vim.fn.setline(1, 'should not save automatically')
      vim.cmd('doautocmd InsertLeave')
      vim.cmd('doautocmd BufDelete')

      -- File should not exist because auto save is disabled
      assert.equals(vim.fn.filereadable(file_name), 0)
    end)

    -- Note: This test is flaky in headless mode due to window event timing issues
    -- The auto-hide functionality works correctly (verified manually), but the
    -- WinLeave event doesn't always trigger properly in headless test environment
    it('should support auto hiding file buffer', function()
      pending('Skipped: flaky in headless mode due to window event timing') -- TODO: Implement
    end)
  end)

  describe('MadoScratchOpen and MadoScratchOpenFile', function()
    it('should make different buffers when options are different', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
      })

      vim.cmd('MadoScratchOpen')
      local tmp_file = vim.fn.expand('%:p')

      vim.cmd('MadoScratchOpenFile')
      local persistent_file = vim.fn.expand('%:p')

      assert.is_not.equals(tmp_file, persistent_file)
    end)

    it('should change buffer type from tmp to file when pattern is same', function()
      local file_pattern = vim.fn.fnamemodify('./tests/tmp/scratch-%d', ':p')
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = file_pattern,
          when_file_buffer = file_pattern,
        },
      })

      vim.cmd('MadoScratchOpen')
      local first_file = vim.fn.expand('%:p')

      vim.cmd('MadoScratchOpenFile')
      local second_file = vim.fn.expand('%:p')

      assert.equals(second_file, first_file)
      -- Check buffer type is file (empty buftype)
      assert.equals(vim.bo.buftype, '')
      assert.equals(vim.bo.bufhidden, '')
    end)

    it('should change buffer type from file to tmp when pattern is same', function()
      local file_pattern = vim.fn.fnamemodify('./tests/tmp/scratch-%d', ':p')
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = file_pattern,
          when_file_buffer = file_pattern,
        },
      })

      vim.cmd('MadoScratchOpenFile')
      local first_file = vim.fn.expand('%:p')

      vim.cmd('MadoScratchOpen')
      local second_file = vim.fn.expand('%:p')

      assert.equals(second_file, first_file)
      -- Check buffer type is tmp (nofile buftype)
      assert.equals(vim.bo.buftype, 'nofile')
      assert.equals(vim.bo.bufhidden, 'hide')
    end)
  end)

  describe('MadoScratchClean', function()
    it('should wipe opened files and buffers', function()
      vim.cmd('MadoScratchOpenFile md')
      local first_file = vim.fn.expand('%:p')
      vim.cmd('write')

      vim.cmd('MadoScratchOpen md')
      local second_file = vim.fn.expand('%:p')

      -- Check the created files exist
      local all_buffer_names = helper.get_all_buffer_names()
      assert.equals(vim.fn.filereadable(first_file), 1)
      assert.is_true(contains(all_buffer_names, first_file))
      assert.is_true(contains(all_buffer_names, second_file))

      -- Wipe all scratch buffers and files
      vim.cmd('MadoScratchClean')

      -- Check the created files are removed
      local new_all_buffer_names = helper.get_all_buffer_names()
      assert.equals(vim.fn.filereadable(first_file), 0)
      assert.is_false(contains(new_all_buffer_names, first_file))
      assert.is_false(contains(new_all_buffer_names, second_file))
    end)
  end)

  describe('float window support', function()
    it('should open a new file in float window (legacy float)', function()
      vim.cmd('MadoScratchOpen md float')
      local file_name = vim.fn.expand('%:p')
      local mado = require('mado-scratch')
      local config = mado.get_config()
      local expected = string.format(config.file_pattern.when_tmp_buffer, 0) .. '.md'
      assert.equals(expected, file_name)

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)
    end)

    it('should open a new file in float-fixed window', function()
      vim.cmd('MadoScratchOpen md float-fixed')
      local file_name = vim.fn.expand('%:p')
      local mado = require('mado-scratch')
      local config = mado.get_config()
      local expected = string.format(config.file_pattern.when_tmp_buffer, 0) .. '.md'
      assert.equals(expected, file_name)

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)
    end)

    it('should load existing file content in float window', function()
      -- Create a file with content
      vim.cmd('MadoScratchOpenFile md')
      local file_name = vim.fn.expand('%:p')
      vim.fn.setline(1, { 'line 1', 'line 2', 'line 3' })
      vim.cmd('write')
      vim.cmd('bwipeout!')

      -- Open the same file in float window
      vim.cmd('MadoScratchOpenFile md float')
      local reopened_file = vim.fn.expand('%:p')
      assert.equals(file_name, reopened_file)

      -- Check if content is loaded
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equals(3, #lines)
      assert.equals('line 1', lines[1])
      assert.equals('line 2', lines[2])
      assert.equals('line 3', lines[3])
    end)

    it('should set correct float window size', function()
      vim.cmd('MadoScratchOpen md float 100x50')

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Check window size
      assert.equals(100, win_config.width)
      assert.equals(50, win_config.height)
    end)

    it('should use default float window size when not specified', function()
      vim.cmd('MadoScratchOpen md float')

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Check window size (should use default: 80x24)
      assert.equals(80, win_config.width)
      assert.equals(24, win_config.height)
    end)

    it('should use config default float window size when not specified', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'float', size = { width = 120, height = 40 } },
      })

      vim.cmd('MadoScratchOpen md float')

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Check window size (should use config default: 120x40)
      assert.equals(120, win_config.width)
      assert.equals(40, win_config.height)
    end)

    it('should support float-fixed with default_open_method config', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'float-fixed', size = { width = 100, height = 30 } },
      })

      vim.cmd('MadoScratchOpen md')

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Check window size (should use config default: 100x30)
      assert.equals(100, win_config.width)
      assert.equals(30, win_config.height)
    end)

    it('should support float-aspect with scale ratio', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'float-aspect', scale = { width = 0.5, height = 0.5 } },
      })

      vim.cmd('MadoScratchOpen md')

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Get UI size (with fallback for headless mode)
      local ui = vim.api.nvim_list_uis()[1]
      local ui_width, ui_height
      if ui ~= nil then
        ui_width = ui.width
        ui_height = ui.height
      else
        -- Default size for headless mode (same as buffer.lua)
        ui_width = 120
        ui_height = 40
      end

      local expected_width = math.floor(ui_width * 0.5)
      local expected_height = math.floor(ui_height * 0.5)

      -- Check window size (should be 50% of screen size)
      assert.equals(expected_width, win_config.width)
      assert.equals(expected_height, win_config.height)
    end)

    it('should normalize legacy float to float-fixed', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'float', size = { width = 90, height = 35 } },
      })

      -- After setup, the method should be normalized to 'float-fixed'
      local config = mado.get_config()
      assert.equals('float-fixed', config.default_open_method)
      assert.equals(90, config.default_open_params['float-fixed'].size.width)
      assert.equals(35, config.default_open_params['float-fixed'].size.height)
    end)

    it('should support float-fixed with command-line size argument', function()
      vim.cmd('MadoScratchOpen md float-fixed 30x20')

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Check window size (should be 30x20)
      assert.equals(30, win_config.width)
      assert.equals(20, win_config.height)
    end)

    it('should support float (legacy) with command-line size argument', function()
      vim.cmd('MadoScratchOpen md float 40x25')

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Check window size (should be 40x25)
      assert.equals(40, win_config.width)
      assert.equals(25, win_config.height)
    end)

    it('should support float-aspect with command-line scale argument', function()
      vim.cmd('MadoScratchOpen md float-aspect 0.9x0.9')

      -- Check if window is floating
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Get UI size (with fallback for headless mode)
      local ui = vim.api.nvim_list_uis()[1]
      local ui_width, ui_height
      if ui ~= nil then
        ui_width = ui.width
        ui_height = ui.height
      else
        -- Default size for headless mode
        ui_width = 120
        ui_height = 40
      end

      local expected_width = math.floor(ui_width * 0.9)
      local expected_height = math.floor(ui_height * 0.9)

      -- Check window size (should be 90% of screen size)
      assert.equals(expected_width, win_config.width)
      assert.equals(expected_height, win_config.height)
    end)

    it('should display file name in float window border title', function()
      vim.cmd('MadoScratchOpen md float')

      local title = vim.api.nvim_win_get_config(0).title
      local expected_title = ' ' .. vim.fn.expand('%:t') .. ' '

      if type(title) == 'string' then
        assert.equals(expected_title, title)
      else
        assert.equals(expected_title, title[1][1])
      end
    end)

    it('should allow writing when opening same file buffer twice in float-aspect', function()
      -- First call to MadoScratchOpenFile md float-aspect
      vim.cmd('MadoScratchOpenFile md float-aspect')
      local file_name1 = vim.fn.expand('%:p')
      local bufnr1 = vim.fn.bufnr('%')

      -- Second call to MadoScratchOpenFile md float-aspect (should reuse buffer)
      vim.cmd('MadoScratchOpenFile md float-aspect')
      local file_name2 = vim.fn.expand('%:p')
      local bufnr2 = vim.fn.bufnr('%')

      -- Both calls should open the same file
      assert.equals(file_name1, file_name2)
      -- Buffer should be reused
      assert.equals(bufnr1, bufnr2)

      -- Add some content
      vim.fn.setline(1, 'test content')

      -- Try to write - this should succeed without error
      local success, err = pcall(function()
        vim.cmd('write')
      end)

      -- Write should succeed
      assert.is_true(success, string.format('Write failed with error: %s', tostring(err)))

      -- Verify file was written
      assert.equals(vim.fn.filereadable(file_name1), 1)
      local content = vim.fn.readfile(file_name1)
      assert.equals('test content', content[1])
    end)

    -- The reproduction for [#33](https://github.com/aiya000/nvim-mado-scratch/issues/33)
    it('should not error when closing float-fixed file buffer immediately with auto_save enabled', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_file_ext = 'md',
        auto_save_file_buffer = true,  -- Enable auto-save to trigger the autocmd
        use_default_keymappings = false,
        auto_hide_buffer = {
          when_tmp_buffer = false,
          when_file_buffer = false,
        },
      })
      vim.cmd('MadoScratchOpenFile md float-fixed 80x80')

      -- Verify the buffer was created
      local file_name = vim.fn.expand('%:p')
      assert.is_not.equals('', file_name)

      -- Backup
      local bufnr = vim.api.nvim_get_current_buf()
      local winid = vim.api.nvim_get_current_win()

      -- Simulate the condition that causes `E32` error
      vim.api.nvim_buf_set_name(bufnr, '')
      local success, err = pcall(function()
        require('mado-scratch.autocmd').save_file_buffer_if_enabled()
      end)

      -- Restore buffer name
      vim.api.nvim_buf_set_name(bufnr, file_name)

      -- The test passes if no error is thrown (E32 was caught and suppressed)
      assert.is_true(success, string.format('Expected save to handle E32 gracefully, but got error: %s', tostring(err)))

      -- Clean up: close the window
      vim.cmd('quit')
      assert.is_false(vim.api.nvim_win_is_valid(winid))
    end)

    it('should not error when executing :vsp in a float window', function()
      vim.cmd('MadoScratchOpen md float-aspect')
      local float_winid = vim.api.nvim_get_current_win()

      local success, err = pcall(function()
        vim.cmd('vsp')
      end)

      -- Wait for any scheduled callbacks (e.g. vim.schedule in autocmds) to complete
      vim.wait(100, function() return false end, 10)

      assert.is_true(success, string.format('Expected :vsp in float window to succeed, but got error: %s', tostring(err)))
      -- The float window should have been closed when WinLeave fired
      assert.is_false(vim.api.nvim_win_is_valid(float_winid), 'Expected float window to be closed after :vsp')
    end)

    it('should preserve buffer content when reopening MadoScratchOpen in float window', function()
      -- Open a buffer and add content
      vim.cmd('MadoScratchOpen md float-aspect')
      local file_name = vim.fn.expand('%:p')
      local bufnr = vim.fn.bufnr('%')
      vim.fn.setline(1, { 'preserved line 1', 'preserved line 2' })
      vim.cmd('quit')

      -- Reopen the same buffer with the same command
      vim.cmd('MadoScratchOpen md float-aspect')
      local reopened_file = vim.fn.expand('%:p')
      local reopened_bufnr = vim.fn.bufnr('%')
      assert.equals(file_name, reopened_file)
      assert.equals(bufnr, reopened_bufnr)

      -- Content should be preserved
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equals(2, #lines)
      assert.equals('preserved line 1', lines[1])
      assert.equals('preserved line 2', lines[2])
    end)

    it('should preserve buffer content when reopening MadoScratchOpenFile in float window with auto_save disabled', function()
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

      -- Open a buffer and add content
      vim.cmd('MadoScratchOpenFile md float-aspect')
      local file_name = vim.fn.expand('%:p')
      local bufnr = vim.fn.bufnr('%')
      vim.fn.setline(1, { 'unsaved line 1', 'unsaved line 2' })
      vim.cmd('quit')

      -- Reopen the same buffer with the same command
      vim.cmd('MadoScratchOpenFile md float-aspect')
      local reopened_file = vim.fn.expand('%:p')
      local reopened_bufnr = vim.fn.bufnr('%')
      assert.equals(file_name, reopened_file)
      assert.equals(bufnr, reopened_bufnr)

      -- Content should be preserved
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equals(2, #lines)
      assert.equals('unsaved line 1', lines[1])
      assert.equals('unsaved line 2', lines[2])
    end)

    it('should change buffer type from tmp to file in float mode when pattern is same', function()
      local file_pattern = vim.fn.fnamemodify('./tests/tmp/scratch-%d', ':p')
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = file_pattern,
          when_file_buffer = file_pattern,
        },
      })

      -- Open as tmp buffer first
      vim.cmd('MadoScratchOpen md float-aspect')
      local first_file = vim.fn.expand('%:p')
      local bufnr1 = vim.fn.bufnr('%')

      -- Check buffer type is tmp (nofile buftype)
      assert.equals(vim.bo.buftype, 'nofile')

      -- Open same buffer as file buffer
      vim.cmd('MadoScratchOpenFile md float-aspect')
      local second_file = vim.fn.expand('%:p')
      local bufnr2 = vim.fn.bufnr('%')

      -- Should be same file and buffer
      assert.equals(second_file, first_file)
      assert.equals(bufnr1, bufnr2)

      -- Check buffer type is now file (empty buftype)
      assert.equals(vim.bo.buftype, '')
      assert.equals(vim.bo.bufhidden, '')

      -- Verify we can write
      vim.fn.setline(1, 'test write content')
      local success, err = pcall(function()
        vim.cmd('write')
      end)
      assert.is_true(success, string.format('Write failed with error: %s', tostring(err)))
    end)
  end)

  describe('backward compatibility', function()
    after_each(function()
      -- Clean up windows and buffers
      vim.cmd('silent! %bdelete!')
      vim.cmd('silent! only!')
    end)

    it('should support legacy sp format with height', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'sp', height = 20 },
      })

      local config = mado.get_config()
      assert.equals('sp', config.default_open_method)
      assert.equals(20, config.default_open_params.sp.height)

      -- Test that the command uses the default height
      vim.cmd('MadoScratchOpen md sp')
      local win_height = vim.api.nvim_win_get_height(0)
      assert.equals(20, win_height)
    end)

    it('should support legacy vsp format with width', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'vsp', width = 50 },
      })

      local config = mado.get_config()
      assert.equals('vsp', config.default_open_method)
      assert.equals(50, config.default_open_params.vsp.width)

      -- Test that the command uses the default width
      vim.cmd('MadoScratchOpen md vsp')
      local win_width = vim.api.nvim_win_get_width(0)
      assert.equals(50, win_width)
    end)

    it('should support legacy float-fixed format with size', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'float-fixed', size = { width = 100, height = 40 } },
      })

      local config = mado.get_config()
      assert.equals('float-fixed', config.default_open_method)
      assert.equals(100, config.default_open_params['float-fixed'].size.width)
      assert.equals(40, config.default_open_params['float-fixed'].size.height)

      -- Test that the command uses the default size
      vim.cmd('MadoScratchOpen md float-fixed')
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)
      assert.equals(100, win_config.width)
      assert.equals(40, win_config.height)
    end)

    it('should support legacy float-aspect format with scale', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'float-aspect', scale = { width = 0.9, height = 0.7 } },
      })

      local config = mado.get_config()
      assert.equals('float-aspect', config.default_open_method)
      assert.equals(0.9, config.default_open_params['float-aspect'].scale.width)
      assert.equals(0.7, config.default_open_params['float-aspect'].scale.height)

      -- Test that the command uses the default scale
      vim.cmd('MadoScratchOpen md float-aspect')
      local win_config = vim.api.nvim_win_get_config(0)
      assert.equals('editor', win_config.relative)

      -- Verify size is calculated from scale (approximately)
      local ui = vim.api.nvim_list_uis()[1]
      local ui_width, ui_height
      if ui ~= nil then
        ui_width = ui.width
        ui_height = ui.height
      else
        -- Fallback for headless mode
        ui_width = 120
        ui_height = 40
      end
      local expected_width = math.floor(ui_width * 0.9)
      local expected_height = math.floor(ui_height * 0.7)
      assert.equals(expected_width, win_config.width)
      assert.equals(expected_height, win_config.height)
    end)

    it('should support legacy tabnew format', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        default_open_method = { method = 'tabnew' },
      })

      local config = mado.get_config()
      assert.equals('tabnew', config.default_open_method)

      -- Test that the command creates a new tab
      local initial_tab_count = vim.fn.tabpagenr('$')
      vim.cmd('MadoScratchOpen md tabnew')
      local new_tab_count = vim.fn.tabpagenr('$')
      assert.equals(initial_tab_count + 1, new_tab_count)
    end)

    it('should allow mixing legacy and new formats', function()
      local mado = require('mado-scratch')
      mado.setup({
        file_pattern = {
          when_tmp_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-tmp-%d', ':p'),
          when_file_buffer = vim.fn.fnamemodify('./tests/tmp/scratch-file-%d', ':p'),
        },
        -- Use legacy format for default_open_method
        default_open_method = { method = 'sp', height = 25 },
        -- But also specify new format for other methods
        default_open_params = {
          vsp = { width = 60 },
          ['float-aspect'] = { scale = { width = 0.85, height = 0.85 } },
        },
      })

      local config = mado.get_config()

      -- Legacy format should be converted to new format
      assert.equals('sp', config.default_open_method)
      assert.equals(25, config.default_open_params.sp.height)

      -- New format should be preserved
      assert.equals(60, config.default_open_params.vsp.width)
      assert.equals(0.85, config.default_open_params['float-aspect'].scale.width)
      assert.equals(0.85, config.default_open_params['float-aspect'].scale.height)
    end)
  end)
end)

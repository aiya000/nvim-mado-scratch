describe('mado-scratch-buffer', function()
  local buffer_module = require('mado-scratch-buffer.buffer')
  local helper_module = require('mado-scratch-buffer.helper')

  -- Test temporary directory
  local test_tmp_dir = vim.fn.fnamemodify('./tests/tmp', ':p')

  before_each(function()
    -- Clean up environment before each test
    vim.cmd('silent! %bwipe!')

    -- Create test tmp directory
    vim.fn.mkdir(test_tmp_dir, 'p')

    -- Set test configuration
    require('mado-scratch-buffer').setup({
      file_pattern = {
        when_tmp_buffer = test_tmp_dir .. '/mado-scratch-tmp-%d',
        when_file_buffer = test_tmp_dir .. '/mado-scratch-file-%d',
      },
      default_file_ext = 'md',
      default_open_method = 'sp',
      default_buffer_size = 30,
      auto_save_file_buffer = false,
      use_default_keymappings = false,
      auto_hide_buffer = {
        when_tmp_buffer = false,
        when_file_buffer = false,
      },
    })

    -- Clean all created scratch files and buffers
    buffer_module.clean()

    -- Start with a clean single window
    vim.cmd('new')
    vim.cmd('only')
  end)

  after_each(function()
    -- Clean up test files
    local files = vim.fn.glob(test_tmp_dir .. '/mado-scratch-*', false, true)
    for _, file in ipairs(files) do
      vim.fn.delete(file)
    end

    -- Clean buffers
    buffer_module.clean()
  end)

  describe('MadoScratchBufferOpen', function()
    it('should create a tmp buffer', function()
      buffer_module.open(false)
      local file_name = vim.fn.expand('%:p')
      local expected = test_tmp_dir .. '/mado-scratch-tmp-0.md'
      assert.equals(expected, file_name)

      -- Check buffer type for tmp buffer
      assert.equals('nofile', vim.bo.buftype)
      assert.equals('hide', vim.bo.bufhidden)
    end)

    it('should accept file extension argument', function()
      buffer_module.open(false, 'ts')
      local file_name = vim.fn.expand('%:p')
      local expected = test_tmp_dir .. '/mado-scratch-tmp-0.ts'
      assert.equals(expected, file_name)
    end)

    it('should accept open method argument', function()
      local initial_winnr = vim.fn.winnr()
      buffer_module.open(false, 'md', 'vsp')
      -- Should have opened in a new vertical split
      assert.is_true(vim.fn.winnr('$') > 1)
    end)

    it('should accept buffer size argument', function()
      buffer_module.open(false, 'md', 'sp', 10)
      assert.equals(10, vim.fn.winheight(0))
    end)
  end)

  describe('MadoScratchBufferOpenNext', function()
    it('should create multiple different buffers', function()
      buffer_module.open(false)
      local first_file = vim.fn.expand('%:p')

      buffer_module.open(true) -- opening_next_fresh_buffer = true
      local second_file = vim.fn.expand('%:p')

      assert.are_not.equals(first_file, second_file)
    end)

    it('should create sequential numbered buffers', function()
      -- Don't clean between calls in this test
      buffer_module.open(true) -- First buffer (should be index 1)
      local first_file = vim.fn.expand('%:p')

      buffer_module.open(true) -- Second buffer (should be index 2)
      local second_file = vim.fn.expand('%:p')

      -- Extract indices and verify they're sequential
      local first_index = first_file:match('mado%-scratch%-tmp%-(%d+)%.md')
      local second_index = second_file:match('mado%-scratch%-tmp%-(%d+)%.md')

      assert.equals('1', first_index)
      assert.equals('2', second_index)
      assert.are_not.equals(first_file, second_file)
    end)
  end)

  describe('MadoScratchBufferOpenFile', function()
    it('should create a persistent file buffer', function()
      buffer_module.open_file(false)
      local file_name = vim.fn.expand('%:p')
      local expected = test_tmp_dir .. '/mado-scratch-file-0.md'
      assert.equals(expected, file_name)

      -- Check buffer type for file buffer
      assert.equals('', vim.bo.buftype)
      assert.equals('', vim.bo.bufhidden)
    end)

    it('should be writable', function()
      buffer_module.open_file(false)
      vim.fn.setline(1, 'test content')

      -- Should be able to write without error
      local success = pcall(vim.cmd, 'write')
      assert.is_true(success)

      -- Check file was actually written
      local file_name = vim.fn.expand('%:p')
      local content = vim.fn.readfile(file_name)
      assert.equals('test content', content[1])
    end)
  end)

  describe('MadoScratchBufferOpenFileNext', function()
    it('should create multiple different file buffers', function()
      buffer_module.open_file(false)
      local first_file = vim.fn.expand('%:p')

      buffer_module.open_file(true) -- opening_next_fresh_buffer = true
      local second_file = vim.fn.expand('%:p')

      assert.are_not.equals(first_file, second_file)
    end)
  end)

  describe('MadoScratchBufferClean', function()
    it('should remove all scratch buffers and files', function()
      -- Create some buffers and files
      buffer_module.open_file(false, 'md')
      local file_buffer = vim.fn.expand('%:p')
      vim.cmd('write')

      buffer_module.open(false, 'md')
      local tmp_buffer = vim.fn.expand('%:p')

      -- Verify they exist
      local buffer_names = helper_module.get_all_buffer_names()
      assert.is_true(helper_module.contains(buffer_names, file_buffer))
      assert.is_true(helper_module.contains(buffer_names, tmp_buffer))
      assert.equals(1, vim.fn.filereadable(file_buffer))

      -- Clean up
      buffer_module.clean()

      -- Verify they're gone
      local new_buffer_names = helper_module.get_all_buffer_names()
      assert.is_false(helper_module.contains(new_buffer_names, file_buffer))
      assert.is_false(helper_module.contains(new_buffer_names, tmp_buffer))
      assert.equals(0, vim.fn.filereadable(file_buffer))
    end)
  end)

  describe('Configuration', function()
    it('should use default configuration values', function()
      -- Test with custom defaults
      require('mado-scratch-buffer').setup({
        file_pattern = {
          when_tmp_buffer = test_tmp_dir .. '/custom-tmp-%d',
          when_file_buffer = test_tmp_dir .. '/custom-file-%d',
        },
        default_file_ext = 'ts',
        default_open_method = 'vsp',
        default_buffer_size = 20,
      })

      vim.cmd('new') -- Create another window to test sizing
      buffer_module.open(false)

      local file_name = vim.fn.expand('%:p')
      local expected = test_tmp_dir .. '/custom-tmp-0.ts'
      assert.equals(expected, file_name)
      assert.equals(20, vim.fn.winwidth(0))
    end)
  end)

  describe('Buffer reuse logic', function()
    it('should reuse existing buffer when opening non-next buffer', function()
      buffer_module.open(true) -- Create first buffer (index 1)
      local first_file = vim.fn.expand('%:p')

      -- Move to different window
      vim.cmd('new')

      buffer_module.open(false) -- Should open the most recent buffer index (index 1)
      local second_file = vim.fn.expand('%:p')

      assert.equals(first_file, second_file)
    end)
  end)
end)

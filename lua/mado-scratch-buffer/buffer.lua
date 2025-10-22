local helper = require('mado-scratch-buffer.helper')

local M = {}

---@class OpenBufferOptions
---@field opening_as_tmp_buffer boolean # Whether opening as tmp buffer
---@field opening_next_fresh_buffer boolean # Whether to open next fresh buffer
---@field file_ext string | nil
---@field open_method string | nil
---@field buffer_size integer | 'no-auto-resize' | nil

---Extracts index from name using pattern
---@param name string # Buffer or file name
---@param pattern string # Pattern with %d placeholder
---@return integer | nil # Index number, or nil if not found
local function extract_index_from_name(name, pattern)
  -- Replace %d with a unique placeholder that won't appear in paths
  local temp_placeholder = '__INDEX__'
  local protected_pattern = pattern:gsub('%%d', temp_placeholder)

  -- Escape special regex characters for Vim regex
  -- Characters that are special in Vim regex: . * [ ] ^ $ \ (special handling for \)
  local escaped_pattern = protected_pattern
    :gsub('%.', '\\.')  -- Escape dots
    :gsub('%*', '\\*')  -- Escape asterisks
    :gsub('%-', '\\-')  -- Escape hyphens
    :gsub('%^', '\\^')  -- Escape carets
    :gsub('%$', '\\$')  -- Escape dollar signs
    :gsub('%[', '\\[')  -- Escape open brackets
    :gsub('%]', '\\]')  -- Escape close brackets

  -- Replace placeholder with capture group for digits
  local getting_index_regex = escaped_pattern:gsub(temp_placeholder, '\\([0-9]\\+\\)')

  local matches = vim.fn.matchlist(name, getting_index_regex)
  if #matches > 1 then
    return tonumber(matches[2])
  end
  return nil
end

---Finds current max index for pattern
---@param pattern string # File pattern with %d placeholder
---@return integer # Maximum index found (0 if none)
local function find_current_index(pattern)
  local buffer_names = helper.get_all_buffer_names()
  local max_buffer_index = 0

  -- Find max index from buffer names
  for _, buffer_name in ipairs(buffer_names) do
    local index = extract_index_from_name(buffer_name, pattern)
    if index and index > max_buffer_index then
      max_buffer_index = index
    end
  end

  -- Find max index from files
  local file_glob_pattern = pattern:gsub('%%d', '*')
  local files = vim.fn.glob(file_glob_pattern, false, true)
  local max_file_index = 0

  for _, file_name in ipairs(files) do
    local index = extract_index_from_name(file_name, pattern)
    if index and index > max_file_index then
      max_file_index = index
    end
  end

  return math.max(max_buffer_index, max_file_index)
end

---Returns file pattern with extension
---@param opening_as_tmp_buffer boolean # Whether opening as tmp buffer
---@param file_ext string # File extension or special value
---@return string # File pattern with extension
local function get_file_pattern(opening_as_tmp_buffer, file_ext)
  local config = require('mado-scratch-buffer').get_config()
  local base_pattern = opening_as_tmp_buffer
    and config.file_pattern.when_tmp_buffer
    or config.file_pattern.when_file_buffer

  if file_ext == '--no-file-ext' or file_ext == '' then
    return base_pattern
  else
    return base_pattern .. '.' .. file_ext
  end
end

---Wipes buffers matching pattern
---@param file_pattern string # Pattern to match buffers
local function wipe_buffers(file_pattern)
  -- Create a prefix by removing the %d placeholder and any extension
  local base_pattern = file_pattern:gsub('%%d.*$', '')
  local buffer_names = helper.get_all_buffer_names()

  for _, buffer_name in ipairs(buffer_names) do
    -- Check if buffer name starts with the base pattern (using plain text match)
    if buffer_name ~= '' and buffer_name:sub(1, #base_pattern) == base_pattern then
      local bufnr = vim.fn.bufnr(buffer_name)
      if bufnr ~= -1 then
        vim.cmd('bwipe! ' .. bufnr)
      end
    end
  end
end

---@param opening_as_tmp_buffer boolean
local function set_buffer_type(opening_as_tmp_buffer)
  if opening_as_tmp_buffer then
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'hide'
  else
    vim.bo.buftype = ''
    vim.bo.bufhidden = ''
  end
end

local function get_winsize()
  local ui = vim.api.nvim_list_uis()[1]
  if ui ~= nil then
    return ui.width, ui.height
  else
    return 120, 40 -- Default size
  end
end

---Edits file in a new floating window
---@param file_name string
---@param geometry { width: integer, height: integer, row: integer, col: integer }
local function open_in_new_float_window(file_name, geometry)
  local bufnr = vim.api.nvim_create_buf(false, false)

  local is_file_not_opened_by_another_neovim = pcall(vim.api.nvim_buf_set_name, bufnr, file_name)
  if not is_file_not_opened_by_another_neovim then
    vim.notify(
      'Warning: Another Neovim instance may be editing this file: ' .. file_name,
      vim.log.levels.WARN
    )
    local lines = vim.fn.readfile(file_name)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end

  vim.api.nvim_open_win(bufnr, true, {
    relative = 'editor',
    width = geometry.width,
    height = geometry.height,
    row = geometry.row,
    col = geometry.col,
    style = 'minimal',
    border = 'rounded',
  })
end

---Opens a floating window with a buffer displaying the specified file
---@param buffer_size integer | 'no-auto-resize'
---@param file_name string
local function open_float_buffer(buffer_size, file_name)
  local width = tonumber(buffer_size) or 80 -- 80: A default width
  local height = math.floor(width / 2)
  local win_width, win_height = get_winsize()
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  open_in_new_float_window(file_name, {
    width = width,
    height = height,
    row = row,
    col = col,
  })
end

---Opens a window by specified method
---@param open_method 'sp' | 'vsp' | 'tabnew'
---@param buffer_size integer | 'no-auto-resize'
---@param file_name string
local function open_buffer_by_method(open_method, buffer_size, file_name)
  vim.cmd(('silent %s %s'):format(open_method, vim.fn.fnameescape(file_name)))
  if buffer_size ~= 'no-auto-resize' then
    local resize_method = open_method == 'vsp' and 'vertical resize' or 'resize'
    vim.cmd(resize_method .. ' ' .. tonumber(buffer_size))
  end
end

---Opens a scratch buffer (either a tmp buffer or a file buffer)
---@param options OpenBufferOptions
function M.open_buffer(options)
  local config = require('mado-scratch-buffer').get_config()

  local file_ext = options.file_ext or config.default_file_ext
  local file_pattern = get_file_pattern(options.opening_as_tmp_buffer, file_ext)

  local index = find_current_index(file_pattern) + (options.opening_next_fresh_buffer and 1 or 0)
  local file_name = vim.fn.expand(string.format(file_pattern, index))

  local open_method = options.open_method or config.default_open_method
  local buffer_size = options.buffer_size or config.default_buffer_size

  if open_method == 'float' then
    open_float_buffer(buffer_size, file_name)
  else
    open_buffer_by_method(
      open_method --[[@as 'sp' | 'vsp' | 'tabnew']],
      buffer_size,
      file_name
    )
  end
  set_buffer_type(options.opening_as_tmp_buffer)
end

---Opens scratch buffer (tmp buffer)
---@param opening_next_fresh_buffer boolean Whether to force new buffer
---@param ... string # Expected: { file_ext?, open_method?, buffer_size? }
function M.open(opening_next_fresh_buffer, ...)
  return M.open_buffer({
    opening_as_tmp_buffer = true,
    opening_next_fresh_buffer = opening_next_fresh_buffer,
    file_ext = select(1, ...),
    open_method = select(2, ...),
    buffer_size = select(3, ...),
  })
end

---Opens a file buffer (persistent buffer)
---@param opening_next_fresh_buffer boolean --Whether to force new buffer
---@param ... string # Expected: { file_ext?, open_method?, buffer_size? }
function M.open_file(opening_next_fresh_buffer, ...)
  return M.open_buffer({
    opening_as_tmp_buffer = false,
    opening_next_fresh_buffer = opening_next_fresh_buffer,
    file_ext = select(1, ...),
    open_method = select(2, ...),
    buffer_size = select(3, ...),
  })
end

---Cleans up all scratch buffers and files
function M.clean()
  local config = require('mado-scratch-buffer').get_config()

  local file_glob_pattern = config.file_pattern.when_file_buffer:gsub('%%d', '*')
  local persistent_files = vim.fn.glob(file_glob_pattern, false, true)
  for _, persistent_file in ipairs(persistent_files) do
    vim.fn.delete(persistent_file)
  end

  wipe_buffers(config.file_pattern.when_tmp_buffer)
  wipe_buffers(config.file_pattern.when_file_buffer)
end

return M

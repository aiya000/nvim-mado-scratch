local helper = require('scratch-buffer.helper')

local M = {}

--- Extract index from name using pattern
--- @param name string Buffer or file name
--- @param pattern string Pattern with %d placeholder
--- @return number|nil index Index number or nil if not found
local function extract_index_from_name(name, pattern)
  local getting_index_regex = pattern:gsub('%%d', '(%%d+)')
  local matches = vim.fn.matchlist(name, getting_index_regex)
  if #matches > 1 then
    return tonumber(matches[2])
  end
  return nil
end

--- Find current max index for pattern
--- @param pattern string File pattern with %d placeholder
--- @return number max_index Maximum index found (0 if none)
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

--- Get file pattern with extension
--- @param opening_as_tmp_buffer boolean Whether opening as tmp buffer
--- @param file_ext string File extension or special value
--- @return string pattern File pattern with extension
local function get_file_pattern(opening_as_tmp_buffer, file_ext)
  local config = require('scratch-buffer').config
  local base_pattern = opening_as_tmp_buffer
    and config.file_pattern.when_tmp_buffer
    or config.file_pattern.when_file_buffer

  if file_ext == '--no-file-ext' or file_ext == '' then
    return base_pattern
  else
    return base_pattern .. '.' .. file_ext
  end
end

--- Wipe buffers matching pattern
--- @param file_pattern string Pattern to match buffers
local function wipe_buffers(file_pattern)
  local scratch_prefix = '^' .. file_pattern:gsub('%%d', '')
  local buffer_names = helper.get_all_buffer_names()

  for _, buffer_name in ipairs(buffer_names) do
    if buffer_name:match(scratch_prefix) then
      local bufnr = vim.fn.bufnr(buffer_name)
      if bufnr ~= -1 then
        vim.cmd('bwipe! ' .. bufnr)
      end
    end
  end
end

--- Open scratch buffer
--- @param options table Options for opening buffer
--- @return nil
function M.open_buffer(options)
  local config = require('scratch-buffer').config
  local autocmd = require('scratch-buffer.autocmd')

  local args = options.args or {}
  local opening_as_tmp_buffer = options.opening_as_tmp_buffer
  local opening_next_fresh_buffer = options.opening_next_fresh_buffer

  -- Setup autocmds
  autocmd.setup_autocmds()

  local file_ext = args[1] or config.default_file_ext
  local file_pattern = get_file_pattern(opening_as_tmp_buffer, file_ext)

  local index = find_current_index(file_pattern) + (opening_next_fresh_buffer and 1 or 0)
  local file_name = vim.fn.expand(string.format(file_pattern, index))

  local open_method = args[2] or config.default_open_method
  local buffer_size = args[3] and tonumber(args[3]) or config.default_buffer_size

  -- Open buffer
  vim.cmd(('silent %s %s'):format(open_method, vim.fn.fnameescape(file_name)))

  -- Set buffer options
  if opening_as_tmp_buffer then
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'hide'
  else
    vim.bo.buftype = ''
    vim.bo.bufhidden = ''
  end

  -- Resize buffer if size specified
  if buffer_size then
    local resize_cmd = open_method == 'vsp' and 'vertical resize' or 'resize'
    vim.cmd(resize_cmd .. ' ' .. buffer_size)
  end
end

--- Open scratch buffer (tmp buffer)
--- @param opening_next_fresh_buffer boolean Whether to force new buffer
--- @param ... any Arguments (file_ext, open_method, buffer_size)
function M.open(opening_next_fresh_buffer, ...)
  return M.open_buffer({
    opening_as_tmp_buffer = true,
    opening_next_fresh_buffer = opening_next_fresh_buffer,
    args = { ... }
  })
end

--- Open file buffer (persistent buffer)
--- @param opening_next_fresh_buffer boolean Whether to force new buffer
--- @param ... any Arguments (file_ext, open_method, buffer_size)
function M.open_file(opening_next_fresh_buffer, ...)
  return M.open_buffer({
    opening_as_tmp_buffer = false,
    opening_next_fresh_buffer = opening_next_fresh_buffer,
    args = { ... }
  })
end

--- Clean up all scratch buffers and files
function M.clean()
  local config = require('scratch-buffer').config

  -- Delete persistent files
  local file_glob_pattern = config.file_pattern.when_file_buffer:gsub('%%d', '*')
  local persistent_files = vim.fn.glob(file_glob_pattern, false, true)

  for _, persistent_file in ipairs(persistent_files) do
    vim.fn.delete(persistent_file)
  end

  -- Wipe buffers
  wipe_buffers(config.file_pattern.when_tmp_buffer)
  wipe_buffers(config.file_pattern.when_file_buffer)
end

return M
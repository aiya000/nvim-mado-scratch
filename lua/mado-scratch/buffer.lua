local arrow = require('mado-scratch.luarrow.arrow').arrow
local c = require('mado-scratch.chotto')
local fn = require('mado-scratch.functions')

local M = {}

local default_sp_height = 15
local default_vsp_width = 30
local default_float_fixed_size = { width = 80, height = 24 }
local default_float_aspect_scale = { width = 0.8, height = 0.8 }

---@class OpenBufferOptions
---@field opening_as_tmp_buffer boolean -- Whether opening as tmp buffer
---@field opening_next_fresh_buffer boolean -- Whether to open next fresh buffer
---@field file_ext string | nil
---@field open_method string | nil
---@field buffer_size string | nil

---Opens scratch buffer (tmp buffer)
---@param opening_next_fresh_buffer boolean -- Whether to force new buffer
---@param ... string -- Expected: { file_ext?, open_method?, buffer_size? }
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
---@param opening_next_fresh_buffer boolean -- Whether to force new buffer
---@param ... string -- Expected: { file_ext?, open_method?, buffer_size? }
function M.open_file(opening_next_fresh_buffer, ...)
  return M.open_buffer({
    opening_as_tmp_buffer = false,
    opening_next_fresh_buffer = opening_next_fresh_buffer,
    file_ext = select(1, ...),
    open_method = select(2, ...),
    buffer_size = select(3, ...),
  })
end

---Extracts index from name using pattern
---@param name string -- Buffer or file name
---@param pattern string -- Pattern with %d placeholder
---@return integer | nil -- Index number, or nil if not found
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
---@param pattern string -- File pattern with %d placeholder
---@return integer -- Maximum index found (0 if none)
local function find_current_index(pattern)
  local buffer_names = fn.get_all_buffer_names()
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
---@param opening_as_tmp_buffer boolean -- Whether opening as tmp buffer
---@param file_ext string -- File extension or special value
---@return string -- File pattern with extension
local function get_file_pattern(opening_as_tmp_buffer, file_ext)
  local config = require('mado-scratch').get_config()
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
---@param file_pattern string -- Pattern to match buffers
local function wipe_buffers(file_pattern)
  -- Create a prefix by removing the %d placeholder and any extension
  local base_pattern = file_pattern:gsub('%%d.*$', '')
  local buffer_names = fn.get_all_buffer_names()

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

---Gets opening Neovim's window size
local function get_neovim_winsize()
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
  -- Check if buffer with this name already exists
  local existing_bufnr = vim.fn.bufnr(file_name)
  
  if existing_bufnr ~= -1 then
    -- If the buffer has unsaved changes and is a file buffer, save the content
    local is_modified = vim.api.nvim_buf_get_option(existing_bufnr, 'modified')
    local buftype = vim.api.nvim_buf_get_option(existing_bufnr, 'buftype')
    
    if is_modified and buftype ~= 'nofile' then
      -- Get the buffer contents and write to file to preserve changes
      local buffer_lines = vim.api.nvim_buf_get_lines(existing_bufnr, 0, -1, false)
      vim.fn.writefile(buffer_lines, file_name)
    end
    
    -- Now it's safe to delete the buffer
    vim.api.nvim_buf_delete(existing_bufnr, { force = true })
  end

  local Popup = require('nui.popup')
  local popup = Popup({
    enter = true,
    focusable = true,
    border = { style = 'rounded' },
    relative = 'editor',
    position = { row = geometry.row, col = geometry.col },
    size = { width = geometry.width, height = geometry.height },
  })
  popup:mount()
  local bufnr = popup.bufnr

  vim.api.nvim_buf_set_name(bufnr, file_name)

  if vim.fn.filereadable(file_name) == 1 then
    local lines = vim.fn.readfile(file_name)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    group = vim.api.nvim_create_augroup('MadoScratchBufSync', { clear = false }),
    buffer = bufnr,
    callback = function()
      if vim.bo[bufnr].buftype == 'nofile' then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      vim.fn.writefile(lines, file_name)
      vim.api.nvim_buf_set_option(bufnr, 'modified', false)
    end,
  })
end

---Opens a floating window with a buffer displaying the specified file
---@param size { width: integer, height: integer }
---@param file_name string
local function open_floating_window(size, file_name)
  local width = size.width
  local height = size.height
  local win_width, win_height = get_neovim_winsize()
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  open_in_new_float_window(file_name, {
    width = width,
    height = height,
    row = row,
    col = col,
  })
end

---Parses float window size from string
---@param size_str string | nil
---@return { width: integer, height: integer } | nil
local function parse_float_fixed_size(size_str)
  if size_str == nil then
    return nil
  end

  local width, height = size_str:match('^(%d+)x(%d+)$')
  if width ~= nil and height ~= nil then
    return { width = tonumber(width), height = tonumber(height) }
  end

  return nil
end

---@param float_scale { width: number, height: number }
---@return { width: integer, height: integer }
local function convert_float_aspect_scale_to_size(float_scale)
  local win_width, win_height = get_neovim_winsize()
  return {
    width = math.floor(win_width * float_scale.width),
    height = math.floor(win_height * float_scale.height),
  }
end

---Parses float window aspect ratio scale from string
---@param scale_str string | nil
---@return { width: number, height: number } | nil
local function parse_float_aspect_scale(scale_str)
  if scale_str == nil then
    return nil
  end

  local width, height = scale_str:match('^([%d%.]+)x([%d%.]+)$')
  if width ~= nil and height ~= nil then
    return { width = tonumber(width), height = tonumber(height) }
  end

  return nil
end

---@param open_method 'float-fixed' | 'float' | 'float-aspect'
---@param buffer_size string | nil
---@return { width: integer, height: integer }
local function get_actual_floating_buffer_size(open_method, buffer_size)
  fn.ensure(
    c.union({
      c.literal('float-fixed'),
      c.literal('float'),
      c.literal('float-aspect'),
    }),
    open_method
  )
  fn.ensure(
    c.union({ c.string(), c.null() }),
    buffer_size
  )
  local config = require('mado-scratch').get_config()

  if buffer_size == nil and (open_method == 'float-fixed' or open_method == 'float') then
    return config.default_open_method.size
      or fn.fallback(
        "No size for 'float-fixed' specified, and config.default_open_method.size is nil. Fallback",
        default_float_fixed_size
      )
  end
  if buffer_size == nil and open_method == 'float-aspect' then
    return convert_float_aspect_scale_to_size(
      config.default_open_method.scale
        or fn.fallback(
          "No scale for 'float-aspect' specified, and config.default_open_method.scale is nil. Fallback",
          default_float_aspect_scale
        )
    )
  end
  buffer_size = buffer_size --[[@as string]]

  if open_method == 'float-fixed' or open_method == 'float' then
    return parse_float_fixed_size(buffer_size) or error('Invalid buffer_size for float-fixed method: ' .. tostring(buffer_size))
  end
  if open_method == 'float-aspect' then
    return parse_float_aspect_scale(buffer_size)
      % arrow(function(scale)
        return scale ~= nil
          and convert_float_aspect_scale_to_size(scale)
          or error('Invalid buffer_size for float-aspect method: ' .. tostring(buffer_size))
      end)
  end

  error('Reached supposedly unreachable code in open_floating_buffer. "Invalid open_method". Please report this.')
end

---Opens a window for 'float-fixed', 'float', or 'float-aspect' method
---@param open_method 'float-fixed' | 'float' | 'float-aspect'
---@param buffer_size string | nil
---@param file_name string
local function open_floating_buffer(open_method, buffer_size, file_name)
  open_floating_window(
    get_actual_floating_buffer_size(open_method, buffer_size),
    file_name
  )
end

---@param open_method 'sp' | 'vsp' | 'tabnew'
---@param buffer_size string | nil
---@return integer | 'no-auto-resize'
local function get_actual_non_floating_buffer_size(open_method, buffer_size)
  if buffer_size == 'no-auto-resize' then
    return 'no-auto-resize'
  end

  if buffer_size ~= nil then
    return tonumber(buffer_size) or fn.fallback(
      ("Unknown buffer_size (%s). Fallback to 'no-auto-resize'"):format(tostring(buffer_size)),
      'no-auto-resize'
    )
  end

  -- Use default size if not specified
  local config = require('mado-scratch').get_config()
  return open_method == 'sp'
    and (config.default_open_method.height or default_sp_height)
    or open_method == 'vsp'
      and (config.default_open_method.width or default_vsp_width)
      or open_method == 'tabnew'
        and 'no-auto-resize'
        or error('Reached supposedly unreachable code in open_no_floating_buffer. Please report this.')
end

---Opens a window for 'sp', 'vsp', or 'tabnew' method
---@param open_method 'sp' | 'vsp' | 'tabnew'
---@param buffer_size string | nil
---@param file_name string
local function open_no_floating_buffer(open_method, buffer_size, file_name)
  fn.ensure(
    c.union({ c.literal('sp'), c.literal('vsp'), c.literal('tabnew') }),
    open_method
  )

  vim.cmd(('silent %s %s'):format(open_method, vim.fn.fnameescape(file_name)))

  local actual_buffer_size = get_actual_non_floating_buffer_size(open_method, buffer_size)
  if actual_buffer_size ~= 'no-auto-resize' then
    local resize_method = open_method == 'vsp' and 'vertical resize' or 'resize'
    vim.cmd(resize_method .. ' ' .. actual_buffer_size)
  end
end

---Opens a scratch buffer (either a tmp buffer or a file buffer)
---@param options OpenBufferOptions
function M.open_buffer(options)
  local config = require('mado-scratch').get_config()

  local file_ext = options.file_ext or config.default_file_ext
  local file_pattern = get_file_pattern(options.opening_as_tmp_buffer, file_ext)

  local index = find_current_index(file_pattern) + (options.opening_next_fresh_buffer and 1 or 0)
  local file_name = vim.fn.expand(file_pattern:format(index))

  local open_method = options.open_method or config.default_open_method.method
  local buffer_size = options.buffer_size

  if open_method == 'float-fixed' or open_method == 'float' or open_method == 'float-aspect' then
    open_floating_buffer(
      open_method --[[@as 'float-fixed' | 'float' | 'float-aspect']],
      buffer_size,
      file_name
    )
  elseif open_method == 'sp' or open_method == 'vsp' or open_method == 'tabnew' then
    open_no_floating_buffer(
      open_method --[[@as 'sp' | 'vsp' | 'tabnew']],
      buffer_size,
      file_name
    )
  else
    vim.notify(
      ("Unknown open method ('%s'). Fallback to 'sp'"):format(tostring(open_method)),
      vim.log.levels.WARN
    )
    open_no_floating_buffer('sp', buffer_size, file_name)
  end

  set_buffer_type(options.opening_as_tmp_buffer)
end

---Cleans up all scratch buffers and files
function M.clean()
  local config = require('mado-scratch').get_config()

  local file_glob_pattern = config.file_pattern.when_file_buffer:gsub('%%d', '*')
  local persistent_files = vim.fn.glob(file_glob_pattern, false, true)
  for _, persistent_file in ipairs(persistent_files) do
    vim.fn.delete(persistent_file)
  end

  wipe_buffers(config.file_pattern.when_tmp_buffer)
  wipe_buffers(config.file_pattern.when_file_buffer)
end

return M

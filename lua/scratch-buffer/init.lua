local M = {}

-- Default configuration
local default_config = {
  file_pattern = {
    when_tmp_buffer = '/tmp/mado-scratch-tmp-%d',
    when_file_buffer = '/tmp/mado-scratch-file-%d',
  },
  default_file_ext = 'md',
  default_open_method = 'sp',
  default_buffer_size = 15,
  auto_save_file_buffer = true,
  use_default_keymappings = false,
  auto_hide_buffer = {
    when_tmp_buffer = false,
    when_file_buffer = false,
  },
}

-- Plugin configuration
M.config = {}

--- Deep merge two tables
--- @param target table Target table to merge into
--- @param source table Source table to merge from
--- @return table merged Merged table
local function deep_merge(target, source)
  local result = vim.deepcopy(target)
  for k, v in pairs(source) do
    if type(v) == 'table' and type(result[k]) == 'table' then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end


--- Setup keymappings
local function setup_keymappings()
  if not M.config.use_default_keymappings then
    return
  end

  local opts = { silent = true, noremap = true }

  -- Quick open commands (execute immediately)
  vim.keymap.set('n', '<leader>b', '<Cmd>MadoScratchBufferOpen<CR>', opts)
  vim.keymap.set('n', '<leader>B', '<Cmd>MadoScratchBufferOpenFile<CR>', opts)

  -- Interactive commands (allows adding arguments)
  vim.keymap.set('n', '<leader><leader>b', ':<C-u>MadoScratchBufferOpen ', { noremap = true })
  vim.keymap.set('n', '<leader><leader>B', ':<C-u>MadoScratchBufferOpenFile ', { noremap = true })
end

--- Setup the plugin
--- @param user_config table|nil User configuration
function M.setup(user_config)
  user_config = user_config or {}

  -- Merge with default config
  M.config = deep_merge(default_config, user_config)

  -- Setup keymappings if enabled
  setup_keymappings()

  -- Mark as loaded
  vim.g.loaded_mado_scratch_buffer = true
end

--- Get current configuration
--- @return table config Current configuration
function M.get_config()
  return M.config
end

return M
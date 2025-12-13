local M = {}

---@class mado_scratch.Options
---@field file_pattern? {when_tmp_buffer?: string, when_file_buffer?: string}
---@field default_file_ext? string
---@field default_open_method? 'vsp' | 'sp' | 'tabnew' -- TODO: Add 'float' support. See Issue #1
---@field default_buffer_size? number | 'no-auto-resize'
---@field auto_save_file_buffer? boolean
---@field use_default_keymappings? boolean
---@field auto_hide_buffer? {when_tmp_buffer?: boolean, when_file_buffer?: boolean}

---@type mado_scratch.Options
local default_config = {
  file_pattern = {
    when_tmp_buffer = '/tmp/mado-scratch-tmp-%d',
    when_file_buffer = '/tmp/mado-scratch-file-%d',
  },
  default_file_ext = 'md',
  default_open_method = 'sp',
  default_buffer_size = 30,
  auto_save_file_buffer = true,
  use_default_keymappings = false,
  auto_hide_buffer = {
    when_tmp_buffer = false,
    when_file_buffer = false,
  },
}

---@type mado_scratch.Options
M.config = {}

---Merges two tables deeply
---@param target mado_scratch.Options --The target table to merge into
---@param source mado_scratch.Options --The source table to merge from
---@return mado_scratch.Options -- Merged table
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

---Setups default keymappings
local function setup_keymappings()
  vim.keymap.set('n', '<leader>b', '<Cmd>MadoScratchOpen<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader>B', '<Cmd>MadoScratchOpenFile<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader><leader>b', ':<C-u>MadoScratchOpen<Space>', { noremap = true })
  vim.keymap.set('n', '<leader><leader>B', ':<C-u>MadoScratchOpenFile<Space>', { noremap = true })
end

---Setups the plugin
---@param user_config? mado_scratch.Options
function M.setup(user_config)
  M.config = deep_merge(default_config, user_config or {})

  if M.config.use_default_keymappings then
    setup_keymappings()
  end
end

---Returns your current configuration
---@return mado_scratch.Options
function M.get_config()
  return M.config
end

return M

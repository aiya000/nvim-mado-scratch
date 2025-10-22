local M = {}

---A type for user to set nvim-mado-scratch-buffer
---@class mado_scratch_buffer.UserConfig
---@field file_pattern? { when_tmp_buffer?: string, when_file_buffer?: string }
---@field default_file_ext? string
---@field default_open_method? 'vsp' | 'sp' | 'tabnew' | 'float'
---@field default_buffer_size? integer | 'no-auto-resize'
---@field auto_save_file_buffer? boolean
---@field use_default_keymappings? boolean
---@field auto_hide_buffer? { when_tmp_buffer?: boolean, when_file_buffer?: boolean }

---A completed type for nvim-mado-scratch-buffer configuration.
---Not Contains optional fields.
---@class mado_scratch_buffer.Config
---@field file_pattern { when_tmp_buffer: string, when_file_buffer: string }
---@field default_file_ext string
---@field default_open_method 'vsp' | 'sp' | 'tabnew' | 'float'
---@field default_buffer_size integer | 'no-auto-resize'
---@field auto_save_file_buffer boolean
---@field use_default_keymappings boolean
---@field auto_hide_buffer { when_tmp_buffer: boolean, when_file_buffer: boolean }

---@type mado_scratch_buffer.Config | nil
local config = nil

local function define_default_keymaps()
  vim.keymap.set('n', '<leader>b', '<Cmd>MadoScratchBufferOpen<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader>B', '<Cmd>MadoScratchBufferOpenFile<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader><leader>b', ':<C-u>MadoScratchBufferOpen<Space>', { noremap = true })
  vim.keymap.set('n', '<leader><leader>B', ':<C-u>MadoScratchBufferOpenFile<Space>', { noremap = true })
end

---Setups the plugin
---@param user_config? mado_scratch_buffer.UserConfig
function M.setup(user_config)
  ---@type mado_scratch_buffer.Config
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
  config = vim.tbl_deep_extend('force', default_config, user_config or {})

  if config.use_default_keymappings then
    define_default_keymaps()
  end

  require('mado-scratch-buffer.autocmd').setup_autocmds()
end

---Returns your current configuration.
---Or throws an error if `setup()` is never called.
---@return mado_scratch_buffer.Config
function M.get_config()
  if config == nil then
    error("mado-scratch-buffer is not setup yet. Please call require('mado-scratch-buffer').setup() first.")
  end
  return config
end

return M

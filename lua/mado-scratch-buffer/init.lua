local M = {}

---@class VerticalSplitMethod
---@field method 'vsp'
---@field width? integer

---@class HorizontalSplitMethod
---@field method 'sp'
---@field height? integer

---@class TabNewMethod
---@field method 'tabnew'

---@class FloatWindowMethod
---@field method 'float'
---@field size? { width: integer, height: integer }

---A type for user to set nvim-mado-scratch-buffer
---@class mado_scratch_buffer.UserConfig
---@field file_pattern? { when_tmp_buffer?: string, when_file_buffer?: string }
---@field default_file_ext? string
---@field default_open_method? VerticalSplitMethod | HorizontalSplitMethod | TabNewMethod | FloatWindowMethod
---@field auto_save_file_buffer? boolean
---@field use_default_keymappings? boolean
---@field auto_hide_buffer? { when_tmp_buffer?: boolean, when_file_buffer?: boolean }

---A completed type for nvim-mado-scratch-buffer configuration.
---Not Contains optional fields.
---@class mado_scratch_buffer.Config
---@field file_pattern { when_tmp_buffer: string, when_file_buffer: string }
---@field default_file_ext string
---@field default_open_method VerticalSplitMethod | HorizontalSplitMethod | TabNewMethod | FloatWindowMethod
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
    default_open_method = { method = 'sp', height = 15 },
    auto_save_file_buffer = true,
    use_default_keymappings = false,
    auto_hide_buffer = {
      when_tmp_buffer = false,
      when_file_buffer = false,
    },
  }

  -- デフォルトサイズの定義
  local default_sizes = {
    sp = { height = 15 },
    vsp = { width = 30 },
    float = { width = 80, height = 24 },
  }

  config = vim.tbl_deep_extend('force', default_config, user_config or {})

  -- default_open_methodのサイズがnilの場合、デフォルト値を設定
  if config.default_open_method.method == 'sp' and config.default_open_method.height == nil then
    config.default_open_method.height = default_sizes.sp.height
  elseif config.default_open_method.method == 'vsp' and config.default_open_method.width == nil then
    config.default_open_method.width = default_sizes.vsp.width
  elseif config.default_open_method.method == 'float' and config.default_open_method.size == nil then
    config.default_open_method.size = { width = default_sizes.float.width, height = default_sizes.float.height }
  end

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

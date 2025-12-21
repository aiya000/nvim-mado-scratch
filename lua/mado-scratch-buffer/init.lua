local c = require('mado-scratch-buffer.chotto')
local config_types = require('mado-scratch-buffer.types.config')
local fn = require('mado-scratch-buffer.functions')
local user_config_types = require('mado-scratch-buffer.types.user-config')

local M = {}

---@type mado_scratch_buffer.Config | nil
local config = nil

local function define_default_keymaps()
  vim.keymap.set('n', '<leader>b', '<Cmd>MadoScratchBufferOpen<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader>B', '<Cmd>MadoScratchBufferOpenFile<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader><leader>b', ':<C-u>MadoScratchBufferOpen<Space>', { noremap = true })
  vim.keymap.set('n', '<leader><leader>B', ':<C-u>MadoScratchBufferOpenFile<Space>', { noremap = true })
end

---@param user_config? mado_scratch_buffer.UserConfig
local function define_config_detail(user_config)
  ---@type mado_scratch_buffer.Config
  local default_config = config_types.config_schema:parse({
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
  })

  -- TODO: Notify warn for user instead of `error()`
  config = config_types.config_schema:parse(
    vim.tbl_deep_extend('force', default_config, user_config or {})
  )

  -- TODO: Remove 'float' from 'various places' as this absorbs the difference, although 'float' type is now considered in various places
  -- Normalize 'float' to 'float-fixed' for backward compatibility
  if config.default_open_method.method == 'float' then
    config.default_open_method.method = 'float-fixed'
  end

  -- Apply default sizes if not specified
  local default_sizes = {
    sp = { height = 15 },
    vsp = { width = 30 },
    ['float-fixed'] = { width = 80, height = 24 },
    ['float-aspect'] = { width = 0.8, height = 0.8 },
  }

  if config.default_open_method.method == 'sp' and config.default_open_method.height == nil then
    config.default_open_method.height = default_sizes.sp.height
  elseif config.default_open_method.method == 'vsp' and config.default_open_method.width == nil then
    config.default_open_method.width = default_sizes.vsp.width
  elseif config.default_open_method.method == 'float-fixed' and config.default_open_method.size == nil then
    config.default_open_method.size = {
      width = default_sizes['float-fixed'].width,
      height = default_sizes['float-fixed'].height,
    }
  elseif config.default_open_method.method == 'float-aspect' and config.default_open_method.scale == nil then
    config.default_open_method.scale = {
      width = default_sizes['float-aspect'].width,
      height = default_sizes['float-aspect'].height,
    }
  end
end

---Setups the plugin
---@param user_config? mado_scratch_buffer.UserConfig
function M.setup(user_config)
  fn.ensure(
    c.optional(user_config_types.user_config_schema),
    user_config,
    function(e)
      return "mado-scratch-buffer setup opts structure mismatched: " .. e
    end
  )

  define_config_detail(user_config)
  fn.ensure(config_types.config_schema, config)
  local config_ = config --[[@as mado_scratch_buffer.Config]]

  if config_.use_default_keymappings then
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

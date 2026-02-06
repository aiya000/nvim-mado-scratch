local c = require('mado-scratch.chotto')
local config_types = require('mado-scratch.types.config')
local fn = require('mado-scratch.functions')
local user_config_types = require('mado-scratch.types.user-config')

local M = {}

---@type mado_scratch.Config | nil
local config = nil

local function define_default_keymaps()
  vim.keymap.set('n', '<leader>b', '<Cmd>MadoScratchOpen<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader>B', '<Cmd>MadoScratchOpenFile<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader><leader>b', ':<C-u>MadoScratchOpen<Space>', { noremap = true })
  vim.keymap.set('n', '<leader><leader>B', ':<C-u>MadoScratchOpenFile<Space>', { noremap = true })
end

---@param user_config? mado_scratch.UserConfig
local function define_config_detail(user_config)
  ---@type mado_scratch.Config
  local default_config = config_types.config_schema:parse({
    file_pattern = {
      when_tmp_buffer = '/tmp/mado-scratch-tmp-%d',
      when_file_buffer = '/tmp/mado-scratch-file-%d',
    },
    default_file_ext = 'md',
    default_open_method = 'sp',
    default_open_params = {
      sp = { height = 15 },
      vsp = { width = 30 },
      ['float-fixed'] = { size = { width = 80, height = 24 } },
      ['float-aspect'] = { scale = { width = 0.8, height = 0.8 } },
    },
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

  -- Normalize 'float' to 'float-fixed' for backward compatibility
  if type(config.default_open_method) == 'string' then
    if config.default_open_method == 'float' then
      config.default_open_method = 'float-fixed'
    end
  else
    -- For backward compatibility: if default_open_method is a table (old format),
    -- convert it to the new format with default_open_params
    ---@diagnostic disable-next-line: undefined-field
    local method = config.default_open_method.method

    -- TODO: Remove 'float' from 'various places' as this absorbs the difference, although 'float' type is now considered in various places
    -- Normalize 'float' to 'float-fixed' for backward compatibility
    if method == 'float' then
      method = 'float-fixed'
    end

    -- Extract parameters from the old format
    ---@diagnostic disable-next-line: undefined-field
    if method == 'sp' and config.default_open_method.height then
      config.default_open_params.sp = config.default_open_params.sp or {}
      ---@diagnostic disable-next-line: undefined-field
      config.default_open_params.sp.height = config.default_open_method.height
    ---@diagnostic disable-next-line: undefined-field
    elseif method == 'vsp' and config.default_open_method.width then
      config.default_open_params.vsp = config.default_open_params.vsp or {}
      ---@diagnostic disable-next-line: undefined-field
      config.default_open_params.vsp.width = config.default_open_method.width
    ---@diagnostic disable-next-line: undefined-field
    elseif method == 'float-fixed' and config.default_open_method.size then
      config.default_open_params['float-fixed'] = config.default_open_params['float-fixed'] or {}
      ---@diagnostic disable-next-line: undefined-field
      config.default_open_params['float-fixed'].size = config.default_open_method.size
    ---@diagnostic disable-next-line: undefined-field
    elseif method == 'float-aspect' and config.default_open_method.scale then
      config.default_open_params['float-aspect'] = config.default_open_params['float-aspect'] or {}
      ---@diagnostic disable-next-line: undefined-field
      config.default_open_params['float-aspect'].scale = config.default_open_method.scale
    end

    -- Convert to string format
    config.default_open_method = method
  end

  -- Ensure default_open_params has all method entries
  config.default_open_params.sp = config.default_open_params.sp or {}
  config.default_open_params.vsp = config.default_open_params.vsp or {}
  config.default_open_params['float-fixed'] = config.default_open_params['float-fixed'] or {}
  config.default_open_params['float-aspect'] = config.default_open_params['float-aspect'] or {}
end

---Setups the plugin
---@param user_config? mado_scratch.UserConfig
function M.setup(user_config)
  fn.ensure(
    c.optional(user_config_types.user_config_schema),
    user_config,
    function(e)
      return "mado-scratch setup opts structure mismatched: " .. e
    end
  )

  define_config_detail(user_config)
  fn.ensure(config_types.config_schema, config)
  local config_ = config --[[@as mado_scratch.Config]]

  if config_.use_default_keymappings then
    define_default_keymaps()
  end

  require('mado-scratch.autocmd').setup_autocmds()
end

---Returns your current configuration.
---Or throws an error if `setup()` is never called.
---@return mado_scratch.Config
function M.get_config()
  if config == nil then
    error("mado-scratch is not setup yet. Please call require('mado-scratch').setup() first.")
  end
  return config
end

return M

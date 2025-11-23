---See `mado_scratch_buffer.UserConfig` for configuration what the users can set

local c = require('mado-scratch-buffer.chotto')
local fn = require('mado-scratch-buffer.functions')

local M = {}

---@class VerticalSplitMethod
---@field method 'vsp'
---@field width? integer

M.vertical_split_method_schema = fn.readonly(c.object({
  method = c.literal('vsp'),
  width = c.optional(c.integer()),
}))

---@class HorizontalSplitMethod
---@field method 'sp'
---@field height? integer

M.horizontal_split_method_schema = fn.readonly(c.object({
  method = c.literal('sp'),
  height = c.optional(c.integer()),
}))

---@class TabNewMethod
---@field method 'tabnew'

M.tab_new_method_schema = fn.readonly(c.object({
  method = c.literal('tabnew'),
}))

---@class FloatWindowMethod
---@field method 'float'
---@field size? { width: integer, height: integer }

M.float_window_method_schema = fn.readonly(c.object({
  method = c.literal('float'),
  size = c.optional(
    c.object({
      width = c.integer(),
      height = c.integer(),
    })
  ),
}))

---@alias OpenMethod VerticalSplitMethod | HorizontalSplitMethod | TabNewMethod | FloatWindowMethod

M.open_method_schema = fn.readonly(c.union({
  M.vertical_split_method_schema,
  M.horizontal_split_method_schema,
  M.tab_new_method_schema,
  M.float_window_method_schema,
}))

---A type for user to set nvim-mado-scratch-buffer
---@class mado_scratch_buffer.UserConfig
---@field file_pattern? { when_tmp_buffer?: string, when_file_buffer?: string }
---@field default_file_ext? string
---@field default_open_method? OpenMethod
---@field auto_save_file_buffer? boolean
---@field use_default_keymappings? boolean
---@field auto_hide_buffer? { when_tmp_buffer?: boolean, when_file_buffer?: boolean }

M.user_config_schema = fn.readonly(c.object({
  file_pattern = c.optional(
    c.object({
      when_tmp_buffer = c.optional(c.string()),
      when_file_buffer = c.optional(c.string()),
    })
  ),
  default_file_ext = c.optional(c.string()),
  default_open_method = c.optional(
    c.union({
      M.vertical_split_method_schema,
      M.horizontal_split_method_schema,
      M.tab_new_method_schema,
      M.float_window_method_schema,
    })
  ),
  auto_save_file_buffer = c.optional(c.boolean()),
  use_default_keymappings = c.optional(c.boolean()),
  auto_hide_buffer = c.optional(
    c.object({
      when_tmp_buffer = c.optional(c.boolean()),
      when_file_buffer = c.optional(c.boolean()),
    })
  ),
}))

---A completed type for nvim-mado-scratch-buffer configuration.
---Not Contains optional fields.
---@class mado_scratch_buffer.Config
---@field file_pattern { when_tmp_buffer: string, when_file_buffer: string }
---@field default_file_ext string
---@field default_open_method VerticalSplitMethod | HorizontalSplitMethod | TabNewMethod | FloatWindowMethod
---@field auto_save_file_buffer boolean
---@field use_default_keymappings boolean
---@field auto_hide_buffer { when_tmp_buffer: boolean, when_file_buffer: boolean }

M.config_schema = fn.readonly(c.object({
  file_pattern = c.object({
    when_tmp_buffer = c.string(),
    when_file_buffer = c.string(),
  }),
  default_file_ext = c.string(),
  default_open_method = c.union({
    M.vertical_split_method_schema,
    M.horizontal_split_method_schema,
    M.tab_new_method_schema,
    M.float_window_method_schema,
  }),
  auto_save_file_buffer = c.boolean(),
  use_default_keymappings = c.boolean(),
  auto_hide_buffer = c.object({
    when_tmp_buffer = c.boolean(),
    when_file_buffer = c.boolean(),
  }),
}))

---@type mado_scratch_buffer.Config | nil
local config = nil

local function define_default_keymaps()
  vim.keymap.set('n', '<leader>b', '<Cmd>MadoScratchBufferOpen<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader>B', '<Cmd>MadoScratchBufferOpenFile<CR>', { silent = true, noremap = true })
  vim.keymap.set('n', '<leader><leader>b', ':<C-u>MadoScratchBufferOpen<Space>', { noremap = true })
  vim.keymap.set('n', '<leader><leader>B', ':<C-u>MadoScratchBufferOpenFile<Space>', { noremap = true })
end

---@alias SomeOpenMethodSize
---| { height: integer } # For 'sp'
---| { width: integer } # For 'vsp'
---| { width: integer, height: integer } # For 'float'
---| nil # For 'tabnew'

local some_open_method_size_schema = fn.readonly(
  c.union({
    c.object({ height = c.integer() }),
    c.object({ width = c.integer() }),
    c.object({ width = c.integer(), height = c.integer() }),
    c.literal(nil),
  })
)

---@param open_method OpenMethod
---@return SomeOpenMethodSize
local function get_default_open_method(open_method)
  fn.ensure(M.open_method_schema, open_method)

  local default_sizes = {
    sp = { height = 15 },
    vsp = { width = 30 },
    float = { width = 80, height = 24 },
  }
  return default_sizes[open_method]
end

---@param user_config? mado_scratch_buffer.UserConfig
local function defineConfigDetail(user_config)
  ---@type mado_scratch_buffer.Config
  local default_config = M.config_schema:parse({
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

  config = M.config_schema:parse(vim.tbl_deep_extend('force', default_config, user_config or {}))

  -- Apply default sizes if not specified
  local default_sizes = {
    sp = { height = 15 },
    vsp = { width = 30 },
    float = { width = 80, height = 24 },
  }

  if config.default_open_method.method == 'sp' and config.default_open_method.height == nil then
    config.default_open_method.height = default_sizes.sp.height
  elseif config.default_open_method.method == 'vsp' and config.default_open_method.width == nil then
    config.default_open_method.width = default_sizes.vsp.width
  elseif config.default_open_method.method == 'float' and config.default_open_method.size == nil then
    config.default_open_method.size = { width = default_sizes.float.width, height = default_sizes.float.height }
  end
end

---Setups the plugin
---@param user_config? mado_scratch_buffer.UserConfig
function M.setup(user_config)
  fn.ensure(c.optional(M.user_config_schema), user_config)

  defineConfigDetail(user_config)

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

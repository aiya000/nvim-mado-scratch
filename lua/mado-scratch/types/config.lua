---Defines the types and schemas that this plugin actually handles.
---`./user-config.lua`, the difference is that `mado_scratch_buffer.UserConfig`, allowing some optionality.
---See also `mado_scratch_buffer.UserConfig` for configuration what the users can set.

local c = require('mado-scratch.chotto')

local M = {}

M.vertical_split_method_schema = c.object({
  method = c.literal('vsp'),
  width = c.optional(c.integer()),
})
---@class mado_scratch_buffer.VerticalSplitMethod
---@field method 'vsp'
---@field width? integer

M.horizontal_split_method_schema = c.object({
  method = c.literal('sp'),
  height = c.optional(c.integer()),
})
---@class mado_scratch_buffer.HorizontalSplitMethod
---@field method 'sp'
---@field height? integer

M.tab_new_method_schema = c.object({
  method = c.literal('tabnew'),
})
---@class mado_scratch_buffer.TabNewMethod
---@field method 'tabnew'

M.float_window_fixed_size_method_schema = c.object({
  method = c.union({ c.literal('float-fixed'), c.literal('float') }),
  size = c.optional(
    c.object({
      width = c.integer(),
      height = c.integer(),
    })
  ),
})
---@class mado_scratch_buffer.FloatWindowFixedSizeMethod
---@field method 'float-fixed' | 'float'
---@field size? { width: integer, height: integer }

M.float_window_aspect_ratio_method_schema = c.object({
  method = c.literal('float-aspect'),
  scale = c.optional(
    c.object({
      width = c.number(),
      height = c.number(),
    })
  ),
})
---@class mado_scratch_buffer.FloatWindowAspectRatioMethod
---@field method 'float-aspect'
---@field scale? { width: number, height: number }

M.float_window_method_schema = c.union({
  M.float_window_fixed_size_method_schema,
  M.float_window_aspect_ratio_method_schema,
})
---@alias mado_scratch_buffer.FloatWindowMethod mado_scratch_buffer.FloatWindowFixedSizeMethod | mado_scratch_buffer.FloatWindowAspectRatioMethod

M.open_method_schema = c.union({
  M.vertical_split_method_schema,
  M.horizontal_split_method_schema,
  M.tab_new_method_schema,
  M.float_window_method_schema,
})
---@alias mado_scratch_buffer.OpenMethod mado_scratch_buffer.VerticalSplitMethod | mado_scratch_buffer.HorizontalSplitMethod | mado_scratch_buffer.TabNewMethod | mado_scratch_buffer.FloatWindowMethod

M.config_schema = c.object({
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
})
---A completed type for nvim-mado-scratch configuration.
---Not Contains optional fields.
---@class mado_scratch_buffer.Config
---@field file_pattern { when_tmp_buffer: string, when_file_buffer: string }
---@field default_file_ext string
---@field default_open_method mado_scratch_buffer.OpenMethod
---@field auto_save_file_buffer boolean
---@field use_default_keymappings boolean
---@field auto_hide_buffer { when_tmp_buffer: boolean, when_file_buffer: boolean }

return M

---Defines the type `mado_scratch_buffer.UserConfig`, other types, and schemas,  what the users can set

local c = require('mado-scratch.chotto')
local config_types = require('mado-scratch.types.config')

local M = {}

M.user_config_schema = c.object({
  file_pattern = c.optional(
    c.object({
      when_tmp_buffer = c.optional(c.string()),
      when_file_buffer = c.optional(c.string()),
    })
  ),
  default_file_ext = c.optional(c.string()),
  default_open_method = c.optional(
    c.union({
      config_types.vertical_split_method_schema,
      config_types.horizontal_split_method_schema,
      config_types.tab_new_method_schema,
      config_types.float_window_method_schema,
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
})
---A type for user to set nvim-mado-scratch
---@class mado_scratch_buffer.UserConfig
---@field file_pattern? { when_tmp_buffer?: string, when_file_buffer?: string }
---@field default_file_ext? string
---@field default_open_method? mado_scratch_buffer.OpenMethod
---@field auto_save_file_buffer? boolean
---@field use_default_keymappings? boolean
---@field auto_hide_buffer? { when_tmp_buffer?: boolean, when_file_buffer?: boolean }

return M

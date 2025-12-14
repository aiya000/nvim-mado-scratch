-- Convenience wrapper for embedded luarrow library
-- This allows requiring as: require('deps.luarrow')

-- Get the directory where this file is located
local source = debug.getinfo(1, 'S').source
if source:sub(1, 1) == '@' then
  source = source:sub(2)
end

-- Extract directory path
local dir = source:match('(.*[/\\])')
if not dir then
  dir = '.'
end

-- Add luarrow src directory to package.path if not already present
local luarrow_src_path = dir .. 'luarrow/src/?.lua'
local luarrow_src_init_path = dir .. 'luarrow/src/?/init.lua'

if not package.path:find(luarrow_src_path, 1, true) then
  package.path = luarrow_src_path .. ';' .. luarrow_src_init_path .. ';' .. package.path
end

-- Load and return luarrow
return require('luarrow')

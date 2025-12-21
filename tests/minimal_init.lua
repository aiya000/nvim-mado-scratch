---Minimal init file for running plenary tests

-- Reset runtimepath to avoid loading user config
vim.opt.runtimepath = ''

-- Add only necessary paths
local plenary_path = vim.fn.stdpath('data') .. '/site/pack/vendor/start/plenary.nvim'
local nui_path = vim.fn.stdpath('data') .. '/site/pack/vendor/start/nui.nvim'
local nvim_runtime = vim.fn.expand('$VIMRUNTIME')
local project_path = vim.fn.getcwd()

-- Set minimal runtimepath
vim.opt.runtimepath = nvim_runtime .. ',' .. plenary_path .. ',' .. nui_path .. ',' .. project_path

-- Source the plugin commands
vim.cmd('source ' .. project_path .. '/plugin/mado-scratch-buffer.lua')

---Minimal init file for running plenary tests

-- Reset runtimepath to avoid loading user config
vim.opt.runtimepath = ''

-- Add only necessary paths
local plenary_path = vim.fn.stdpath('data') .. '/site/pack/vendor/start/plenary.nvim'
local nvim_runtime = vim.fn.expand('$VIMRUNTIME')
local project_path = vim.fn.getcwd()

-- Set minimal runtimepath
vim.opt.runtimepath = nvim_runtime .. ',' .. plenary_path .. ',' .. project_path

-- Suppress treesitter errors when parsers are not installed in the test environment.
-- The ftplugin/markdown.lua (and others) call vim.treesitter.start, which throws when
-- the parser binary is unavailable. Wrapping it in pcall prevents those errors from
-- propagating into and breaking unrelated test assertions.
if vim.treesitter and vim.treesitter.start then
  local _orig_ts_start = vim.treesitter.start
  vim.treesitter.start = function(bufnr, lang)
    pcall(_orig_ts_start, bufnr, lang)
  end
end

-- Source the plugin commands
vim.cmd('source ' .. project_path .. '/plugin/mado-scratch.lua')

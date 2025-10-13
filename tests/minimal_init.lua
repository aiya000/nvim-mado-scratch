-- Minimal init file for running plenary tests
-- Add the current directory to runtimepath
vim.opt.runtimepath:append(vim.fn.getcwd())

-- Source the plugin commands
vim.cmd('source ' .. vim.fn.getcwd() .. '/plugin/mado-scratch-buffer.lua')



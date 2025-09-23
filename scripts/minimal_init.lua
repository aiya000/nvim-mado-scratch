-- Minimal init.lua for testing - avoid loading user config
vim.cmd('set rtp&') -- Reset runtimepath to default
vim.opt.runtimepath:prepend('.') -- Add current project

-- Try to add plenary.nvim to runtimepath from common locations
local plenary_paths = {
  vim.fn.expand('~/.local/share/nvim/site/pack/vendor/start/plenary.nvim'),
  vim.fn.expand('~/.local/share/nvim/lazy/plenary.nvim'),
  vim.fn.expand('~/.local/share/nvim/site/pack/packer/start/plenary.nvim'),
  vim.fn.expand('~/.config/nvim/pack/vendor/start/plenary.nvim'),
}

for _, path in ipairs(plenary_paths) do
  if vim.fn.isdirectory(path) == 1 then
    vim.opt.runtimepath:prepend(path)
    break
  end
end

-- Disable all user configs
vim.env.XDG_CONFIG_HOME = '/tmp'
vim.env.XDG_DATA_HOME = '/tmp'
vim.env.XDG_STATE_HOME = '/tmp'

-- Disable swap files and other stuff that might interfere with testing
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false
vim.opt.loadplugins = true

-- Add current directory to path for requiring modules
local current_dir = vim.fn.getcwd()
package.path = package.path .. ';' .. current_dir .. '/lua/?.lua'
package.path = package.path .. ';' .. current_dir .. '/lua/?/init.lua'

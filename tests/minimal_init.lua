-- Minimal init file for running plenary tests
vim.cmd [[set runtimepath=$VIMRUNTIME]]
vim.cmd [[set packpath=/tmp/nvim/site]]

-- Install plenary if not present
local package_root = '/tmp/nvim/site/pack'
local install_path = package_root .. '/packer/start/plenary.nvim'

local function load_plugins()
  require('packer').startup(function(use)
    use 'nvim-lua/plenary.nvim'
    use {
      vim.fn.getcwd(),
      as = 'mado-scratch-buffer',
    }
  end)
end

_G.load_config = function()
  vim.fn.setenv('PLENARY_TEST_TIMEOUT', 60000)
  
  -- Add the current directory to runtimepath
  vim.opt.runtimepath:append(vim.fn.getcwd())
  
  -- Add tests directory
  vim.opt.runtimepath:append(vim.fn.getcwd() .. '/tests')
  
  -- Setup plugin
  require('mado-scratch-buffer').setup()
end

local packer_bootstrap
if vim.fn.isdirectory(install_path) == 0 then
  packer_bootstrap = vim.fn.system({
    'git',
    'clone',
    '--depth=1',
    'https://github.com/nvim-lua/plenary.nvim',
    install_path,
  })
  vim.cmd [[packadd plenary.nvim]]
end

vim.opt.runtimepath:append(vim.fn.getcwd())

-- Load the plugin
require('mado-scratch-buffer').setup()

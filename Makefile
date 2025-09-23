.PHONY: test clean

# Run tests with plenary.nvim
test:
	NVIM_APPNAME=nvim-test nvim --headless --noplugin -u scripts/minimal_init.lua -c "PlenaryBustedDirectory tests" -c "quitall"

# Clean test artifacts
clean:
	rm -rf tests/tmp/

# Install plenary.nvim for testing (requires git)
install-test-deps:
	@echo "To run tests, you need plenary.nvim installed in your Neovim setup."
	@echo "You can install it with your plugin manager, for example:"
	@echo "  - lazy.nvim: { 'nvim-lua/plenary.nvim' }"
	@echo "  - packer.nvim: use 'nvim-lua/plenary.nvim'"
	@echo "  - vim-plug: Plug 'nvim-lua/plenary.nvim'"
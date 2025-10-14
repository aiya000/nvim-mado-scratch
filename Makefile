.PHONY: test help install-plenary clean

# Default target
help:
	@echo "Available targets:"
	@echo "  make test            - Run all tests using plenary.nvim"
	@echo "  make install-plenary - Install plenary.nvim for testing"
	@echo "  make clean           - Clean test artifacts"
	@echo "  make help            - Show this help message"

# Run tests
test:
	@echo "Running plenary tests..."
	@nvim --headless -c "lua require('plenary.test_harness').test_directory('tests/', {minimal_init='tests/minimal_init.lua'})"
	@echo "Tests completed successfully!"

# Install plenary.nvim for testing
install-plenary:
	@echo "Installing plenary.nvim..."
	@mkdir -p ~/.local/share/nvim/site/pack/vendor/start
	@if [ ! -d ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim ]; then \
		git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
			~/.local/share/nvim/site/pack/vendor/start/plenary.nvim; \
		echo "plenary.nvim installed successfully!"; \
	else \
		echo "plenary.nvim is already installed."; \
	fi

# Clean test artifacts
clean:
	@echo "Cleaning test artifacts..."
	@rm -rf tests/tmp/*
	@echo "Clean complete!"

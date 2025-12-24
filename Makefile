.PHONY: test help install-plenary clean update-chotto

# Default target
help:
	@echo 'Available targets:'
	@echo '  make test            - Run all tests using plenary.nvim'
	@echo '  make install-plenary - Install plenary.nvim for testing'
	@echo '  make clean           - Clean test artifacts'
	@echo '  make update-chotto   - Update chotto.lua from upstream and commit changes'
	@echo '  make help            - Show this help message'

# Run tests
test:
	./tests/run_tests.sh

# Install dependencies for testing
install-test-deps:
	$(MAKE) install-plenary

install-plenary:
	@echo 'Installing plenary.nvim...'
	@mkdir -p ~/.local/share/nvim/site/pack/vendor/start
	@if [ ! -d ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim ] ; then \
		git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
			~/.local/share/nvim/site/pack/vendor/start/plenary.nvim ; \
		echo 'plenary.nvim installed successfully!' ; \
	else \
		echo 'plenary.nvim is already installed.' ; \
	fi

# Clean test artifacts
clean:
	@echo 'Cleaning test artifacts...'
	@rm -rf tests/tmp/*
	@echo 'Clean complete!'

# Update chotto.lua from upstream
update-chotto:
	@echo 'Updating chotto.lua from upstream...'
	@git subtree pull --prefix=subtree/chotto.lua https://github.com/aiya000/chotto.lua main --squash
	@echo 'Copying src files to lua/mado-scratch/chotto/...'
	@rm -rf lua/mado-scratch/chotto
	@cp -r subtree/chotto.lua/src lua/mado-scratch/chotto
	@git add lua/mado-scratch/chotto
	@if git diff --cached --quiet; then \
		echo 'No changes to commit.'; \
	else \
		git commit -m "chore: Update chotto.lua to latest version"; \
		echo 'chotto.lua updated and committed successfully!'; \
	fi

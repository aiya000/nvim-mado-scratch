# Tests

This directory contains tests for mado-scratch-buffer.nvim using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

## Running Tests

### Quick Start (Using Makefile)

The easiest way to run tests:

```bash
# Install plenary.nvim
make install-plenary

# Run tests
make test

# See all available targets
make help
```

### Prerequisites

Install plenary.nvim:

```bash
mkdir -p ~/.local/share/nvim/site/pack/vendor/start
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
  ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim
```

### Run All Tests

Using the test script:
```bash
./tests/run_tests.sh
```

Or manually:
```bash
nvim --headless -c "lua require('plenary.test_harness').test_directory('tests/', {minimal_init='tests/minimal_init.lua'})"
```

Or using Make:
```bash
make test
```

## Test Structure

- `mado_scratch_buffer_spec.lua` - Main test suite covering all plugin functionality
- `minimal_init.lua` - Minimal Neovim configuration for running tests
- `tmp/` - Temporary directory for test files (auto-generated, gitignored)

## Writing Tests

Tests use plenary.nvim's busted-style API. Example:

```lua
describe('my feature', function()
  it('should do something', function()
    -- Test code here
    assert.equals(actual, expected)
  end)
end)
```

### Test Conventions

- **Assert argument order**: Use `assert.equals(actual, expected)` - the actual value first, then the expected value.
  - ✅ Correct: `assert.equals(content[1], 'expected text')`
  - ❌ Incorrect: `assert.equals('expected text', content[1])`

See [plenary.nvim documentation](https://github.com/nvim-lua/plenary.nvim) for more details.

# How to run test

The `.github/workflows/test.yml` is actually working, so it is best to look at it.

## The easy way (Using Makefile)

```shell-session
# Install plenary.nvim
$ make install-plenary

# run tests
$ make test

# display help
$ make help
````

## Manual setup

1. Install [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
1. run the test

```shell-session
# Install plenary.nvim (if not already installed)
$ mkdir -p ~/.local/share/nvim/site/pack/vendor/start
$ git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
    ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim

# Run tests
$ cd /path/to/nvim-mado-scratch-buffer
$ nvim --headless -c "lua require('plenary.test_harness').test_directory('tests/', {minimal_init='tests/minimal_init.lua'})"
```

Alternatively, you can use the script provided:

````shell-session
$ ./tests/run_tests.sh
```

# How to run test

`.github/workflows/test.yml` は実際に動いているので、これを見るのが一番わかりやすいですが、一応記しておきます。

## 簡単な方法 (Makefile を使用)

```shell-session
# plenary.nvimのインストール
$ make install-plenary

# テストの実行
$ make test

# ヘルプの表示
$ make help
```

## 手動でのセットアップ

1. [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)をインストールする
1. テストを実行する

```shell-session
# Install plenary.nvim (if not already installed)
$ mkdir -p ~/.local/share/nvim/site/pack/vendor/start
$ git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
    ~/.local/share/nvim/site/pack/vendor/start/plenary.nvim

# Run tests
$ cd /path/to/nvim-mado-scratch-buffer
$ nvim --headless -c "lua require('plenary.test_harness').test_directory('tests/', {minimal_init='tests/minimal_init.lua'})"
```

または、提供されているスクリプトを使用することもできます:

```shell-session
$ ./tests/run_tests.sh
```


#!/usr/bin/env bash

# Script to run tests using plenary.nvim
# This requires plenary.nvim to be installed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo 'Running plenary tests...'
nvim --headless -c "lua require('plenary.test_harness').test_directory('$PROJECT_DIR/tests/', {minimal_init='$PROJECT_DIR/tests/minimal_init.lua'})"

echo 'Tests completed successfully!'

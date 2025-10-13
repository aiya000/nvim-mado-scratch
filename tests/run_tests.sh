#!/usr/bin/env bash

# Script to run tests using plenary.nvim
# This requires plenary.nvim to be installed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Running plenary tests..."
nvim --headless --noplugin -u "$SCRIPT_DIR/minimal_init.lua" \
  -c "PlenaryBustedDirectory $PROJECT_DIR/tests { minimal_init = '$SCRIPT_DIR/minimal_init.lua' }"

echo "Tests completed successfully!"

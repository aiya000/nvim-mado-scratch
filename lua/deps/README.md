# Embedded Dependencies

This directory contains external libraries embedded using git subtree for use within this plugin.

## Luarrow

**Repository:** https://github.com/aiya000/Luarrow.lua

**Description:** A functional programming library providing pipeline operators and function composition for Lua, inspired by Haskell.

**Usage:**

```lua
-- Require the embedded luarrow library
local luarrow = require('deps.luarrow')

-- Use arrow for pipeline operations
local arrow = luarrow.arrow
local result = 42
  % arrow(function(x) return x - 2 end)
  ^ arrow(function(x) return x * 10 end)
  ^ arrow(function(x) return x + 1 end)
print(result) -- 401

-- Use fun for function composition
local fun = luarrow.fun
local function f(x) return x + 1 end
local function g(x) return x * 10 end
local composed = fun(f) * fun(g) % 42
print(composed) -- 401
```

## Updating Embedded Libraries

To update the embedded luarrow library to the latest version:

```bash
git subtree pull --prefix=lua/deps/luarrow https://github.com/aiya000/Luarrow.lua main --squash
```

## Adding New Dependencies

To add a new library using git subtree:

```bash
git subtree add --prefix=lua/deps/[library-name] [repository-url] [branch] --squash
```

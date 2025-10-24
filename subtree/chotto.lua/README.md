# chotto.lua

A TypeScript **Zod-inspired** validation library for Lua with luaCATS force type annotations!

- - -

<div align="center">
<img src="./readme/logo.jpg" alt="logo" width="350"/>
</div>

- - -

**'Chotto'** means **'a little'** in Japanese (**ちょっと**).

I hope this helps you 'a little' when adding types to Lua `:D`

## 🌟 Features

- **Limited type-safe validation** with luaCATS annotations
- **Zod-like API** familiar to TypeScript developers
- **Zero dependencies** -- pure Lua implementation
- **Rich type system** -- objects, arrays, unions, tuples, and more

## 🚀 Quick Start

```lua
local c = require('chotto')

-- Parse and validate with method style (recommended)
local string_result = c.string():parse('hello') -- ✓ returns 'hello'
local number_result = c.number():parse('hello') -- ✗ throws error because 'hello' is not a number
local boolean_result = c.boolean():parse(true) -- ✓ returns true

-- Safe validation with safe_parse (recommended)
local ok, result = c.number():safe_parse(10)
if ok then
  print('Valid:', result) -- Valid: 10
else
  print('Error:', result) -- Error message
end
```

Offcource, you can name `z` instead of `c`, like zod! (lol)

```lua
local z = require('chotto')
local result = z.string():parse('hello')
```

See [Basic Usage](#️-basic-usage) and [Examples](doc/examples.md) for more details.

## 📦 Installation

### With luarocks:

```shell-session
$ luarocks install chotto
```

Check that it is installed correctly:

```shell-session
$ eval $(luarocks path) && lua -e "local c = require('chotto'); print('required correctly!'); print('result:', c.integer():parse(10))"
required correctly!
result: 10
```

### With Git

Possibly, 'With luarocks' method fails on some systems.
If you met such a case, try this:

```shell-session
$ git clone https://github.com/aiya000/chotto.lua
$ cd chotto.lua
```

Then

```shell-session
# Install to your ~/.luarocks
$ make install-to-local
```

Or

```shell-session
# Install globally (might need sudo)
$ luarocks pack <lua-rockspec-file> # <lua-rockspec-file> can be found in git-root. e.g., chotto-main-15.rockspec
$ luarocks make
```

Check that it is installed correctly:

```shell-session
$ eval $(luarocks path) && lua -e "local c = require('chotto'); print('required correctly!'); print('result:', c.integer():parse(10))"
required correctly!
result: 10
```
### Manual installation:

Copy `src/chotto.lua` to your project and require it.

## For Neovim:

After install by 'With luarocks' way, then add this to your `init.lua`:

(This is assuming you are using lua 5.2. Switch these directories to your `.luarocks/share/lua` directory you installed)

```lua
-- Enable packages installed by `luarocks install --local`
package.path = package.path .. ';' .. os.getenv('HOME') .. '/.luarocks/share/lua/5.2/?.lua'
package.path = package.path .. ';' .. os.getenv('HOME') .. '/.luarocks/share/lua/5.2/?/init.lua'
```

If you installed by 'Manual installation', you can simply `require()`.
For example, when you saved chotto.lua to `~/.config/nvim/lua/chotto.lua`, can `require('chotto')`, without adding to `package.path`.

## ⚙️ Basic Usage

### Additional API

chotto.lua also provides these original APIs not found in Zod:

```lua
-- No error is thrown, handler is called instead
c.integer():ensure('not a number', function(err)
  print('Validation failed:', err)
end)

-- The handler is optional.
-- Without a handler, it behaves like :parse() but returns nothing.
c.string():ensure('hello') -- ✓ No error, no return value
c.string():ensure(123) -- ✗ Throws error
```

## 🏗️ Complex Schemas

- All of API is described in [Examples](doc/examples.md)

### Type Annotation Requirements (for Complex Schemas)

For the complex schemas, due to luaCATS limitations, explicit type annotations must append.
Or maybe your variables type inferred to `unknown`.

Append explicit type annotations using `---@type Schema<YourType>` to both schema and parsed result.

Example:
(See below 'Objects' section for usage of object schema.)

- ✅ Correct - with type annotation

```lua
---@alias User {name: string, age: integer}

---@type Schema<User>
local user_schema = c.object({
  name = c.string(),
  age = c.integer(),
})

---@type User
local user = user_schema:parse({
  name = 'Konoko',
  age = 10,
})
```

- ❌ Without annotation - type information is lost

```lua
local schema = c.object({
  name = c.string(),
  age = c.integer(),
})

local user = user_schema:parse({
  name = 'Konoko',
  age = 10,
})
-- `user` cannot be type inferred correctly
```

### Objects

```lua
---@alias User {name: string, age: integer}

---@type Schema<User>
local user_schema = c.object({
  name = c.string(),
  age = c.integer(),
})

---@type User
local user = user_schema:parse({
  name = 'Konoko',
  age = 10,
  extra = 'field', -- Extra fields are preserved (zod-like behavior)
})
```

### Arrays

```lua
---@type Schema<string[]>
local string_array_schema = c.array(c.string())

---@type string[]
local items = string_array_schema:parse({'a', 'b', 'c'})

-- No error is thrown
```

### Unions

```lua
---@type Schema<string | number>
local string_or_number_schema = c.union({
  c.string(),
  c.number()
})

---@type string | number
local konoko = string_or_number_schema:parse('Konoko')
---@type string | number
local ten = string_or_number_schema:parse(10)

-- No error is thrown
```

### Tuples

```lua
---@type Schema<[string, number, boolean]>
local tuple_schema = c.tuple({
  c.string(),
  c.number(),
  c.boolean()
})
```

### Optional

```lua
---@type Schema<{name: string, age?: integer}>
local person_schema = c.object({
  name = c.string(),
  age = c.optional(c.integer()),
})
```

### Literals

```lua
---@type Schema<'success'>
local success_schema = c.literal('success')
---@type 'success'
local success = success_schema:parse('success')

---@type Schema<42>
local truth_schema = c.literal(42)
---@type 42
local truth = truth_schema:parse(42)
```

### Others

- Please see [Examples](doc/examples.md) for all APIs

## 🔄 Relationship to TypeScript Zod

chotto.lua is **strongly inspired** by **TypeScript Zod**, sharing similar:

- **API design patterns** - `.array()`, `.or()`, `.optional()`, `:parse()`, `:safe_parse()`, etc [^design-future]
- **Validation philosophy** - runtime validation with type safety
- **Schema composition** - building complex types from simple ones

[^design-future]: Currently, `.array()`, `.or()`, `.optional()` and etc are not implemented yet. If you want to use these but the implementation hasn't been added yet, please push for it in an issue. lol `:D`

### ✅ What's Similar to Zod

- Object validation with extra field preservation
- Union types for OR validation (`A | B | C`)
- Array and tuple validation
- Optional fields support
- Error throwing on validation failure
- Safe parsing with boolean result (`:safe_parse()` method)
- Validation without return value (`:ensure()` method)

### 🔄 Key Differences from Zod

| Feature | Zod (TypeScript) | chotto.lua |
|---------|------------------|------------|
| **Type Inference** | Automatic | Manual luaCATS annotations required |
| **Method Chaining** | `z.string().optional()` | `c.optional(c.string())` [^design-future] |
| **Reserved Words** | `z.function()`, `z.null()` | `c.func()`, `c.null()` [^because-keyword] |
| **Error Handling** | Try/catch or `.safeParse()` | `:safe_parse()` or `pcall()` |
| **Record Types** | `z.record(z.number())` or `z.record(z.string(), z.number())` | `c.table()` or `c.table(c.string(), c.number())` |
| **Runtime** | TypeScript/JavaScript | Pure Lua |

[^because-keyword]: Because `function` and `nil` are reserved keywords in Lua

## 📚 Documentation

- **[Tutorial](doc/tutorial.md)** - Step-by-step guide and best practices
- **[Examples](doc/examples.md)** - Practical examples and complete API reference
- **[Zod Comparison](doc/zod-comparison.md)** - Detailed comparison with TypeScript Zod

## 🤝 Contributing

Contributions are welcome!
Please check the issues page for current needs.

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Inspired by [Zod](https://github.com/colinhacks/zod) by Colin McDonnell.

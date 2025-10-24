# chotto.lua Examples & API Reference

Comprehensive examples and complete API documentation for chotto.lua.

## Table of Contents

1. [Complete API Reference](#complete-api-reference)
2. [Basic Examples](#basic-examples)
3. [Real-World Use Cases](#real-world-use-cases)
4. [Advanced Patterns](#advanced-patterns)
5. [Integration Examples](#integration-examples)

## Complete API Reference

### Basic Types

```lua
local c = require('chotto')

-- Primitive types
c.string()     -- String validation
c.number()     -- Number validation (integers and floats)
c.integer()    -- Integer-only validation
c.boolean()    -- Boolean validation
c.null()       -- nil validation (note: null, not nil)
c.func()       -- Function validation (note: func, not function)
c.any()        -- Accept any value
c.unknown()    -- Same as any, semantically different
```

### Complex Types

```lua
-- Object validation
c.object(schema_table)

-- Array validation
c.array(item_schema)

-- Optional validation (allows nil)
c.optional(schema)

-- Union validation (OR logic)
c.union(schema_array)

-- Tuple validation (fixed-length array)
c.tuple(schema_array)

-- Table validation (key-value pairs)
c.table()                           -- Any table (`table` type)
c.table(key_schema, value_schema)   -- Typed key-value pairs (`table<K, V>` type)

-- Literal validation (exact value match)
c.literal(value)
```

### Schema Methods

Every schema has two main methods:

```lua
schema:parse(data)              -- Validates and returns data, throws error on failure
schema:safe_parse(data)         -- Returns (true, data) on success or (false, error_msg) on failure
```

There is also an additional method `:ensure()` for validation without return values. See [Validation with ensure()](#validation-with-ensure) for details.

### Primitive Types

```lua
local c = require('chotto')

-- String validation
local name_schema = c.string()
local name = name_schema:parse('Alice')           -- ✓ 'Alice'
-- name_schema:parse(123)                         -- ✗ Error

-- Number validation
local age_schema = c.number()
local age = age_schema:parse(25)                  -- ✓ 25
local height = age_schema:parse(5.9)              -- ✓ 5.9 (floats OK)

-- Integer-only validation
local count_schema = c.integer()
local count = count_schema:parse(42)              -- ✓ 42
-- count_schema:parse(3.14)                       -- ✗ Error (no floats)

-- Boolean validation
local active_schema = c.boolean()
local is_active = active_schema:parse(true)       -- ✓ true

-- Nil validation
local empty_schema = c.null()
local empty = empty_schema:parse(nil)             -- ✓ nil

-- Function validation
local callback_schema = c.func()
local fn = callback_schema:parse(function() end)  -- ✓ function

-- Any value validation
local flexible_schema = c.any()
local anything = flexible_schema:parse('anything') -- ✓ 'anything'
local number = flexible_schema:parse(42)           -- ✓ 42
local table = flexible_schema:parse({})            -- ✓ {}
```

### Object Validation

```lua
-- Basic object
---@type Schema<{name: string, age: integer}>
local person_schema = c.object({
  name = c.string(),
  age = c.integer(),
})

local person = person_schema:parse({
  name = 'Bob',
  age = 30,
  extra = 'field'  -- Extra fields are preserved (zod-like behavior)
})

print(person.name)  -- 'Bob'
print(person.extra) -- 'field'

-- Nested objects
---@type Schema<{user: {name: string, email: string}, settings: {theme: string}}>
local profile_schema = c.object({
  user = c.object({
    name = c.string(),
    email = c.string(),
  }),
  settings = c.object({
    theme = c.string(),
  })
})

local profile = profile_schema:parse({
  user = {
    name = 'Alice',
    email = 'alice@example.com'
  },
  settings = {
    theme = 'dark'
  }
})
```

### Array Validation

```lua
-- String array
---@type Schema<string[]>
local tags_schema = c.array(c.string())
local tags = tags_schema:parse({'lua', 'validation', 'library'})

-- Number array
---@type Schema<number[]>
local scores_schema = c.array(c.number())
local scores = scores_schema:parse({95.5, 87, 92.3})

-- Object array
---@type Schema<{name: string, age: integer}[]>
local users_schema = c.array(c.object({
  name = c.string(),
  age = c.integer(),
}))

local users = users_schema:parse({
  {name = 'Alice', age = 25},
  {name = 'Bob', age = 30}
})

-- Nested arrays
---@type Schema<string[][]>
local matrix_schema = c.array(c.array(c.string()))
local matrix = matrix_schema:parse({
  {'a', 'b', 'c'},
  {'d', 'e', 'f'}
})
```

### Union Types

```lua
-- String or number
---@type Schema<string | number>
local id_schema = c.union({
  c.string(),
  c.number()
})

local id1 = id_schema:parse('user123')  -- ✓ string
local id2 = id_schema:parse(42)         -- ✓ number

-- Status enum
---@type Schema<'pending' | 'success' | 'error'>
local status_schema = c.union({
  c.literal('pending'),
  c.literal('success'),
  c.literal('error')
})

local status = status_schema:parse('success') -- ✓

-- Complex union
---@type Schema<string | {type: 'object', data: table}>
local flexible_data = c.union({
  c.string(),
  c.object({
    type = c.literal('object'),
    data = c.table()
  })
})

local data1 = flexible_data:parse('simple string')
local data2 = flexible_data:parse({
  type = 'object',
  data = {key = 'value'}
})
```

### Optional Fields

```lua
-- Optional string
---@type Schema<string?>
local optional_name = c.optional(c.string())
local name1 = optional_name:parse('Alice')  -- ✓ 'Alice'
local name2 = optional_name:parse(nil)      -- ✓ nil

-- Object with optional fields
---@type Schema<{name: string, nickname?: string, age?: integer}>
local user_schema = c.object({
  name = c.string(),
  nickname = c.optional(c.string()),
  age = c.optional(c.integer())
})

local user1 = user_schema:parse({name = 'Alice'})  -- ✓
local user2 = user_schema:parse({name = 'Bob', nickname = 'Bobby'})  -- ✓
local user3 = user_schema:parse({name = 'Charlie', age = 25})        -- ✓
```

### Tuple Validation

```lua
-- Fixed-length array with different types
---@type Schema<[string, number, boolean]>
local response_tuple = c.tuple({
  c.string(),
  c.number(),
  c.boolean()
})

local response = response_tuple:parse({'success', 200, true})
print(response[1]) -- 'success'
print(response[2]) -- 200
print(response[3]) -- true

-- Coordinate tuple
---@type Schema<[number, number]>
local coordinate = c.tuple({
  c.number(),
  c.number()
})

local point = coordinate:parse({10.5, 20.3})
local x, y = point[1], point[2]
```

### Table Validation

```lua
-- Any table
---@type Schema<table>
local any_table = c.table()
local data = any_table:parse({anything = 'goes', here = 123})

-- String to number mapping
---@type Schema<table<string, number>>
local scores = c.table(c.string(), c.number())
local student_scores = scores:parse({
  alice = 95,
  bob = 87,
  charlie = 92
})

-- String to string mapping
---@type Schema<table<string, string>>
local config = c.table(c.string(), c.string())
local settings = config:parse({
  theme = 'dark',
  language = 'en',
  timezone = 'UTC'
})
```

### Literal Types

```lua
-- Single literal
---@type Schema<'production'>
local env_schema = c.literal('production')
local env = env_schema:parse('production')  -- ✓
-- env_schema:parse('development')          -- ✗ Error

-- Multiple literals via union
---@alias HttpMethod 'GET' | 'POST' | 'PUT' | 'DELETE'

---@type Schema<HttpMethod>
local method_schema = c.union({
  c.literal('GET'),
  c.literal('POST'),
  c.literal('PUT'),
  c.literal('DELETE')
})

---@type HttpMethod
local method = method_schema:parse('POST')

-- Number literals
---@alias HttpStatusCode 200 | 404 | 500

---@type Schema<HttpStatusCode>
local status_code = c.union({
  c.literal(200),
  c.literal(404),
  c.literal(500)
})

---@type HttpStatusCode
local code = status_code:parse(404)
```

## Real-World Use Cases

### API Request/Response Validation

```lua
-- API request validation
---@type Schema<{method: 'GET' | 'POST', url: string, headers?: table<string, string>, body?: string}>
local api_request = c.object({
  method = c.union({
    c.literal('GET'),
    c.literal('POST')
  }),
  url = c.string(),
  headers = c.optional(c.table(c.string(), c.string())),
  body = c.optional(c.string())
})

-- API response validation
---@type Schema<{status: integer, data?: table, error?: string}>
local api_response = c.object({
  status = c.integer(),
  data = c.optional(c.table()),
  error = c.optional(c.string())
})

-- Usage function
local function make_api_call(request_data)
  -- Validate request
  local request, err = pcall(api_request.parse, request_data)
  if err then
    return nil, 'Invalid request: ' .. err
  end

  -- Make the actual call (pseudo-code)
  local raw_response = http.request(request)

  -- Validate response
  local response, err2 = pcall(api_response.parse, raw_response)
  if err2 then
    return nil, 'Invalid response: ' .. err2
  end

  return response, nil
end
```

### Configuration File Validation

```lua
-- Database configuration
---@type Schema<{host: string, port: integer, username: string, password: string, database: string}>
local db_config = c.object({
  host = c.string(),
  port = c.integer(),
  username = c.string(),
  password = c.string(),
  database = c.string()
})

-- Logging configuration
---@type Schema<{level: 'debug' | 'info' | 'warn' | 'error', file?: string, console: boolean}>
local log_config = c.object({
  level = c.union({
    c.literal('debug'),
    c.literal('info'),
    c.literal('warn'),
    c.literal('error')
  }),
  file = c.optional(c.string()),
  console = c.boolean()
})

-- Full application configuration
---@type Schema<{database: {host: string, port: integer, username: string, password: string, database: string}, logging: {level: 'debug' | 'info' | 'warn' | 'error', file?: string, console: boolean}, server: {port: integer, host?: string}}>
local app_config = c.object({
  database = db_config,
  logging = log_config,
  server = c.object({
    port = c.integer(),
    host = c.optional(c.string())
  })
})

-- Configuration loader
local function load_config(config_path)
  local config_data = dofile(config_path) -- or JSON.decode() etc.

  local config, err = pcall(app_config.parse, config_data)
  if err then
    error('Configuration validation failed: ' .. err)
  end

  return config
end
```

### User Input Validation

```lua
-- User registration form
---@alias Registration { username: string, email: string, password: string, age?: integer, terms_accepted: boolean }

---Form validation helper
---@param form_data Registration
---@return Registration | nil, string | nil
local function validate_form(form_data)
  ---@type Schema<Registration>
  local registration_schema = c.object({
    username = c.string(),
    email = c.string(),
    password = c.string(),
    age = c.optional(c.integer()),
    terms_accepted = c.boolean()
  })

  local result, err = pcall(registration_schema.parse, form_data)
  if err then
    return nil, 'Validation failed: ' .. err
  end
  return result, nil
end

-- Usage
local user_data = {
  username = 'alice123',
  email = 'alice@example.com',
  password = 'securepassword',
  terms_accepted = true
}

---@type Registration, string | nil
local user, err = validate_form(user_data)
if err then
  print('Registration failed:', err)
else
  print('User registered:', user.username)
end
```

## Advanced Patterns

### Nesting Schemas

```lua
--- Game State Validation

-- Player data
---@alias Player {name: string, level: integer, health: number, inventory: string[], position: [number, number]}
---@type Schema<Player>
local player_schema = c.object({
  name = c.string(),
  level = c.integer(),
  health = c.number(),
  inventory = c.array(c.string()),
  position = c.tuple({
    c.number(),
    c.number()
  })
})

-- Game state
---@alias GameState {players: Player[], status: 'waiting' | 'playing' | 'finished', round: integer}

---**Nested Schema**
---@type Schema<GameState>
local game_state = c.object({
  players = c.array(player_schema), -- Reuse player_schema
  status = c.union({
    c.literal('waiting'),
    c.literal('playing'),
    c.literal('finished')
  }),
  round = c.integer()
})

-- Save/load game functions
---@param state GameState
---@return boolean, string | nil
local function save_game(state)
  local validated_state, err = pcall(game_state.parse, state)
  if err then
    return false, 'Invalid game state: ' .. err
  end

  -- Save to file
  local file = io.open('savegame.lua', 'w')
  file:write('return ' .. serialize(validated_state))
  file:close()

  return true, nil
end

---@return GameState | nil, string | nil
local function load_game()
  local raw_state = dofile('savegame.lua')

  local state, err = pcall(game_state.parse, raw_state)
  if err then
    return nil, 'Corrupted save file: ' .. err
  end

  return state, nil
end
```

### Recursive Validation

TODO

### Validation Utilities

```lua
-- Safe parsing utility
local function safe_parse(schema, data)
  local ok, result = pcall(schema.parse, data)
  return ok and result or nil, not ok and result or nil
end

-- Validation with default values
local function parse_with_defaults(schema, data, defaults)
  local result, err = safe_parse(schema, data)
  if err then
    return nil, err
  end

  -- Apply defaults for missing optional fields
  for key, default_value in pairs(defaults) do
    if result[key] == nil then
      result[key] = default_value
    end
  end

  return result, nil
end

-- Usage
local config_schema = c.object({
  port = c.optional(c.integer()),
  host = c.optional(c.string()),
  debug = c.optional(c.boolean())
})

local config, err = parse_with_defaults(
  config_schema,
  {port = 8080},
  {host = 'localhost', debug = false}
)
-- Result: {port = 8080, host = 'localhost', debug = false}
```

### Validation with ensure()

The `:ensure()` method is a chotto.lua-specific feature (not in Zod) that validates data without returning a value. It's useful when you only need to validate but don't need the validated result.

```lua
local c = require('chotto')
```

#### Basic usage

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

#### Real-world example

```lua
-- Contract Programming (Design by Contract pattern)

---@generic T
---@param schema chotto.Schema<T>
local function ensure_argument(schema, validatee)
  schema:ensure(validatee, function(e)
    vim.notify('Validation failed: ' .. e, vim.log.levels.ERROR) -- A Neovim API to notify messages
  end)
end

---@param num number
local function print_number(num)
  ensure_argument(c.number(), num)
  print(num)
end
```

```lua
-- Configuration validation
local function validate_config(config)
  local config_schema = c.object({
    port = c.integer(),
    host = c.string(),
    debug = c.boolean()
  })

  -- Ensure config is valid, throw error if not
  config_schema:ensure(config)

  -- If we reach here, config is valid
  print('Configuration is valid!')
end

-- With custom error handling
local function validate_config_safe(config)
  local config_schema = c.object({
    port = c.integer(),
    host = c.string(),
    debug = c.boolean()
  })

  local is_valid = true

  config_schema:ensure(config, function(err)
    print('Configuration error:', err)
    is_valid = false
  end)

  return is_valid
end

-- Usage
validate_config({port = 8080, host = 'localhost', debug = false})  -- ✓
validate_config_safe({port = 'invalid', host = 'localhost'})       -- ✗ Calls handler, returns false
```

## Integration Examples

### Web Framework Integration

```lua
-- Express.js-like framework integration
local function validate_middleware(schema)
  return function(req, res, next)
    local body, err = safe_parse(schema, req.body)
    if err then
      res:status(400):json({error = 'Validation failed: ' .. err})
      return
    end

    req.validated_body = body
    next()
  end
end

-- Route with validation
---@type Schema<{name: string, email: string}>
local create_user_schema = c.object({
  name = c.string(),
  email = c.string()
})

app:post('/users', validate_middleware(create_user_schema), function(req, res)
  local user_data = req.validated_body
  -- user_data is guaranteed to be valid
  local user = create_user(user_data)
  res:json(user)
end)
```

### CLI Argument Validation

```lua
-- Command line argument validation
---@type Schema<{command: 'start' | 'stop' | 'restart', port?: integer, config?: string}>
local cli_args = c.object({
  command = c.union({
    c.literal('start'),
    c.literal('stop'),
    c.literal('restart')
  }),
  port = c.optional(c.integer()),
  config = c.optional(c.string())
})

local function parse_cli_args(args)
  local parsed_args, err = safe_parse(cli_args, args)
  if err then
    print('Invalid arguments: ' .. err)
    print('Usage: program <start|stop|restart> [--port PORT] [--config CONFIG]')
    os.exit(1)
  end

  return parsed_args
end
```

For more detailed usage patterns and migration guides, see [Tutorial](tutorial.md) and [Zod Comparison](zod-comparison.md).

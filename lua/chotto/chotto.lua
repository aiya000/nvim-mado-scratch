local M = {}

---@generic T
---@alias chotto.Validator<T> fun(x: unknown): T

---A schema for validating data
---@generic T
---@class chotto.Schema<T> : { parse_raw: fun(validatee: unknown): T }
---- param `parse_raw` --An internal API to use methods
local Schema = {}
Schema.__index = Schema

---Returns `T` if `validatee` is valid `T`.
---Or throws an error if invalid.
---@generic T
---@param self chotto.Schema<T>
---@param validatee unknown
---@return T
function Schema:parse(validatee)
  return self.parse_raw(validatee)
end

---Simular to `:parse()`, but returns `boolean, T` instead, like:
---```lua
---pcall(function() return foo:parse(validatee) end)
---```
---Returns `true, T` if valid.
---Or `false, string` if invalid (`string` is an error message).
---@generic T
---@param self chotto.Schema<T>
---@param validatee unknown
---@return boolean, T
function Schema:safe_parse(validatee)
  return pcall(function()
    return self:parse(validatee)
  end)
end

---Simular to `:parse()`, but no value returns, and throws an error if `validatee` is invalid.
---Also catches the error by `handle` if provided and an error is thrown.
---@generic T
---@param self chotto.Schema<T>
---@param validatee unknown
---@param handle? fun(err: string)
---@return nil
function Schema:ensure(validatee, handle)
  if handle == nil then
    self:parse(validatee)
    return
  end

  local ok, result = self:safe_parse(validatee)
  if not ok then
    handle(result)
    return
  end
end

---A shorthand for `chotto.Validator`
---@see chotto.Validator
---@generic T
---@alias Validator<T> fun(x: unknown): T

---A shorthand for `chotto.Schema`
---@see chotto.Schema
---@generic T
---@alias Schema<T> chotto.Schema<T>

-- TODO: Add proof to ensure chotto.SomeType and SomeType are identical like
-- const _proof: Equals<chotto.SomeType, SomeType> = true

---@type Validator<integer>
local function is_integer(x)
  if type(x) == 'number' and math.floor(x) == x then
    return x
  end
  error('Expected integer, got: ' .. tostring(x))
end

---@return Schema<integer>
function M.integer()
  return setmetatable({ parse_raw = is_integer }, Schema)
end

---@type Validator<number>
local function is_number(x)
  if type(x) == 'number' then
    return x
  end
  error('Expected number, got: ' .. tostring(x))
end

---@return Schema<number>
function M.number()
  return setmetatable({ parse_raw = is_number }, Schema)
end

---@type Validator<string>
local function is_string(x)
  if type(x) == 'string' then
    return x
  end
  error('Expected string, got: ' .. tostring(x))
end

---@return Schema<string>
function M.string()
  return setmetatable({ parse_raw = is_string }, Schema)
end

---@type Validator<boolean>
local function is_boolean(x)
  if type(x) == 'boolean' then
    return x
  end
  error('Expected boolean, got: ' .. tostring(x))
end

---@return Schema<boolean>
function M.boolean()
  return setmetatable({ parse_raw = is_boolean }, Schema)
end

---@type Validator<nil>
local function is_nil(x)
  if x == nil then
    return nil
  end
  error('Expected nil, got: ' .. tostring(x))
end

---@return Schema<nil>
function M.null()
  return setmetatable({ parse_raw = is_nil }, Schema)
end

---@type Validator<any>
local function is_any(x)
  return x
end

---@return Schema<any>
function M.any()
  return setmetatable({ parse_raw = is_any }, Schema)
end

---@type Validator<unknown>
local function is_unknown(x)
  return x
end

---@return Schema<unknown>
function M.unknown()
  return setmetatable({ parse_raw = is_unknown }, Schema)
end

---@type Validator<function>
local function is_func(x)
  if type(x) == 'function' then
    return x
  end
  error('Expected function, got: ' .. type(x))
end

---@return Schema<function>
function M.func()
  return setmetatable({ parse_raw = is_func }, Schema)
end

---Creates an object schema. The return type should be explicitly annotated.
---```lua
------@type Schema<{a: integer, b: string}>
---local schema = M.object({
---  a = M.integer(),
---  b = M.string(),
---})
---```
---@generic T : table<string, Schema<unknown>>
---@param raw_schema T
---@return Schema<T>
function M.object(raw_schema)
  ---@param obj unknown
  ---@return unknown
  local function is_that_object(obj)
    if type(obj) ~= 'table' then
      error('Expected object, got: ' .. type(obj))
    end

    local validated = {}

    -- Validate all required fields
    for key, schema in pairs(raw_schema) do
      local field_value = obj[key]
      if field_value == nil then
        error('Missing required field: ' .. tostring(key))
      end
      validated[key] = schema.parse_raw(field_value)
    end

    -- Copy over any extra fields (zod-like behavior: allow unknown properties)
    for key, value in pairs(obj) do
      if raw_schema[key] == nil then
        validated[key] = value
      end
    end

    return validated
  end

  return setmetatable({ parse_raw = is_that_object }, Schema)
end

---Creates an array schema. The return type should be explicitly annotated.
---```lua
------@type Schema<integer[]>
---local schema = M.array(M.integer())
---```
---@generic T
---@param item_schema Schema<T>
---@return Schema<T[]>
function M.array(item_schema)
  ---@param arr unknown
  ---@return unknown
  local function is_that_array(arr)
    if type(arr) ~= 'table' then
      error('Expected array, got: ' .. type(arr))
    end

    local validated = {}

    for i, item in ipairs(arr) do
      validated[i] = item_schema.parse_raw(item)
    end

    return validated
  end

  return setmetatable({ parse_raw = is_that_array }, Schema)
end

---Creates an optional schema that accepts nil.
---```lua
------@type Schema<integer?>
---local schema = M.optional(M.integer())
---```
---@generic T
---@param schema Schema<T>
---@return Schema<T | nil>
function M.optional(schema)
  ---@param x unknown
  ---@return unknown
  local function is_optional(x)
    if x == nil then
      return nil
    end
    return schema.parse_raw(x)
  end

  return setmetatable({ parse_raw = is_optional }, Schema)
end

---Creates a union schema that accepts multiple types. Type annotation required.
---```lua
------@type Schema<string | number>
---local schema = M.union({ M.string(), M.number() })
---```
---Due to luaCATS limitation, we can't represent union of types directly
---@generic Schemas : Schema<unknown>[]
---@param schemas Schemas
---@return Schema<unknown[]>
----- NOTE: The below annotation is the ideal form
----- @generic Schemas : Schema<unknown>[]
----- @param schemas Schemas
----- @return Schema<Schemas[number]>
function M.union(schemas)
  ---@param x unknown
  ---@return unknown
  local function is_union(x)
    local errors = {}

    for i, schema in ipairs(schemas) do
      local ok, result = pcall(schema.parse_raw, x)
      if ok then
        return result
      else
        table.insert(errors, 'Option ' .. i .. ': ' .. result)
      end
    end

    error('Union validation failed. Errors: ' .. table.concat(errors, '; '))
  end

  return setmetatable({ parse_raw = is_union }, Schema)
end

---Creates a tuple schema for fixed-length arrays. Type annotation required.
---```lua
------@type Schema<[string, number, boolean]>
---local schema = M.tuple({ M.string(), M.number(), M.boolean() })
---```
-----Due to luaCATS limitation, we can't represent tuple of types directly
---@generic Schemas : Schema<unknown>[]
---@param schemas Schemas
---@return Schema<unknown[]>
----- NOTE: The below annotation is the ideal form
----- @generic Schemas : [...Schema<unknown>[]]
----- @param schemas Schemas
----- @return Schema<Schemas>
function M.tuple(schemas)
  ---@param x unknown
  ---@return unknown
  local function is_tuple(x)
    if type(x) ~= 'table' then
      error('Expected tuple (table), got: ' .. type(x))
    end

    local validated = {}

    for i, schema in ipairs(schemas) do
      local value = x[i]
      if value == nil then
        error('Missing tuple element at index ' .. i)
      end
      validated[i] = schema.parse_raw(value)
    end

    -- Check for extra elements
    for i = #schemas + 1, #x do
      if x[i] ~= nil then
        error('Unexpected extra element at index ' .. i)
      end
    end

    return validated
  end

  return setmetatable({ parse_raw = is_tuple }, Schema)
end

---Creates a table schema. Can be used for general tables or typed key-value pairs.
---```lua
------@type Schema<table>
---local any_table = M.table()
---
------@type Schema<table<string, number>>
---local string_to_number = M.table(M.string(), M.number())
---```
---@generic K, V
---@param key_schema? Schema<K>
---@param value_schema? Schema<V>
---@return Schema<table<K, V>>
function M.table(key_schema, value_schema)
  ---@param x unknown
  ---@return unknown
  local function is_table(x)
    if type(x) ~= 'table' then
      error('Expected table, got: ' .. type(x))
    end

    -- If no schemas provided, accept any table
    if not key_schema and not value_schema then
      return x
    end

    local validated = {}

    for k, v in pairs(x) do
      local validated_key = key_schema and key_schema.parse_raw(k) or k
      local validated_value = value_schema and value_schema.parse_raw(v) or v
      validated[validated_key] = validated_value
    end

    return validated
  end

  return setmetatable({ parse_raw = is_table }, Schema)
end

---Creates a literal schema that only accepts a specific value.
---```lua
------@type Schema<"success">
---local success_schema = M.literal("success")
---```
---@generic T
---@param literal T
---@return Schema<T>
function M.literal(literal)
  ---@param x unknown
  ---@return unknown
  local function is_literal(x)
    if x == literal then
      return x
    end
    error('Expected literal value ' .. tostring(literal) .. ', got: ' .. tostring(x))
  end

  return setmetatable({ parse_raw = is_literal }, Schema)
end

return M

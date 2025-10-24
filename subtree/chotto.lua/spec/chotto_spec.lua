local c = require('chotto')

describe('integer()', function()
  it('should accept integers', function()
    local schema = c.integer()
    assert.are.equal(schema:parse(42), 42)
    assert.are.equal(schema:parse(0), 0)
    assert.are.equal(schema:parse(-10), -10)
  end)

  it('should reject non-integers', function()
    local schema = c.integer()
    assert.has_error(function()
      schema:parse(3.14)
    end)
    assert.has_error(function()
      schema:parse('42')
    end)
    assert.has_error(function()
      schema:parse(nil)
    end)
  end)
end)

describe('string()', function()
  it('should accept strings', function()
    local schema = c.string()
    assert.are.equal(schema:parse('hello'), 'hello')
    assert.are.equal(schema:parse(''), '')
  end)

  it('should reject non-strings', function()
    local schema = c.string()
    assert.has_error(function()
      schema:parse(42)
    end)
    assert.has_error(function()
      schema:parse(nil)
    end)
  end)
end)

describe('number()', function()
  it('should accept numbers', function()
    local schema = c.number()
    assert.are.equal(schema:parse(42), 42)
    assert.are.equal(schema:parse(3.14), 3.14)
    assert.are.equal(schema:parse(-0.5), -0.5)
  end)
end)

describe('boolean()', function()
  it('should accept booleans', function()
    local schema = c.boolean()
    assert.are.equal(schema:parse(true), true)
    assert.are.equal(schema:parse(false), false)
  end)
end)

describe('null()', function()
  it('should accept nil', function()
    local schema = c.null()
    assert.are.equal(schema:parse(nil), nil)
  end)

  it('should reject non-nil values', function()
    local schema = c.null()
    assert.has_error(function()
      schema:parse('not nil')
    end)
    assert.has_error(function()
      schema:parse(42)
    end)
  end)
end)

describe('any()', function()
  it('should accept anything', function()
    local schema = c.any()
    assert.are.equal(schema:parse('hello'), 'hello')
    assert.are.equal(schema:parse(42), 42)
    assert.are.equal(schema:parse(nil), nil)
    assert.are.same(schema:parse({}), {})
  end)
end)

describe('func()', function()
  it('should accept functions', function()
    local schema = c.func()
    local test_func = function() end
    assert.are.equal(schema:parse(test_func), test_func)
  end)

  it('should reject non-functions', function()
    local schema = c.func()
    assert.has_error(function()
      schema:parse('not a function')
    end)
  end)
end)

describe('object()', function()
  it('should validate object structure', function()
    local schema = c.object({
      name = c.string(),
      age = c.integer(),
    })

    local result = schema:parse({ name = 'Alice', age = 30 })
    assert.are.equal(result.name, 'Alice')
    assert.are.equal(result.age, 30)
  end)

  it('should reject missing fields', function()
    local schema = c.object({
      name = c.string(),
      age = c.integer(),
    })

    assert.has_error(function()
      schema:parse({ name = 'Alice' })
    end)
    assert.has_error(function()
      schema:parse({ age = 30 })
    end)
  end)

  it('should allow and preserve unknown fields (zod-like behavior)', function()
    local schema = c.object({
      name = c.string(),
    })

    local result = schema:parse({ name = 'Alice', extra = 'field', another = 42 })
    assert.are.equal(result.name, 'Alice')
    assert.are.equal(result.extra, 'field')
    assert.are.equal(result.another, 42)
  end)
end)

describe('array()', function()
  it('should validate array elements', function()
    local schema = c.array(c.string())

    local result = schema:parse({ 'a', 'b', 'c' })
    assert.are.equal(result[1], 'a')
    assert.are.equal(result[2], 'b')
    assert.are.equal(result[3], 'c')
  end)

  it('should reject invalid elements', function()
    local schema = c.array(c.string())
    assert.has_error(function()
      schema:parse({ 'a', 42, 'c' })
    end)
  end)
end)

describe('optional()', function()
  it('should accept nil', function()
    local schema = c.optional(c.string())
    assert.are.equal(schema:parse(nil), nil)
    assert.are.equal(schema:parse('hello'), 'hello')
  end)
end)

describe('union()', function()
  it('should accept any of the provided types', function()
    local schema = c.union({ c.string(), c.number() })
    assert.are.equal(schema:parse('hello'), 'hello')
    assert.are.equal(schema:parse(42), 42)
  end)

  it('should reject types not in the union', function()
    local schema = c.union({ c.string(), c.number() })
    assert.has_error(function()
      schema:parse(true)
    end)
  end)
end)

describe('tuple()', function()
  it('should validate fixed-length arrays', function()
    local schema = c.tuple({ c.string(), c.number(), c.boolean() })

    local result = schema:parse({ 'hello', 42, true })
    assert.are.equal(result[1], 'hello')
    assert.are.equal(result[2], 42)
    assert.are.equal(result[3], true)
  end)

  it('should reject wrong length', function()
    local schema = c.tuple({ c.string(), c.number() })
    assert.has_error(function()
      schema:parse({ 'hello' })
    end)
    assert.has_error(function()
      schema:parse({ 'hello', 42, 'extra' })
    end)
  end)
end)

describe('table()', function()
  it('should accept any table when no schemas provided', function()
    local schema = c.table()
    local input = { a = 1, b = 'hello' }
    assert.are.same(schema:parse(input), input)
  end)

  it('should validate key-value pairs', function()
    local schema = c.table(c.string(), c.number())

    local result = schema:parse({ hello = 1, world = 2 })
    assert.are.equal(result.hello, 1)
    assert.are.equal(result.world, 2)
  end)
end)

describe('literal()', function()
  it('should only accept the exact value', function()
    local schema = c.literal('success')
    assert.are.equal(schema:parse('success'), 'success')
    assert.has_error(function()
      schema:parse('failure')
    end)
    assert.has_error(function()
      schema:parse('Success')
    end)
  end)

  it('should work with numbers', function()
    local schema = c.literal(42)
    assert.are.equal(schema:parse(42), 42)
    assert.has_error(function()
      schema:parse(41)
    end)
  end)
end)

describe('safe_parse method', function()
  it('should return (true, result) for valid input', function()
    local schema = c.string()
    local ok, result = schema:safe_parse('hello')
    assert.is_true(ok)
    assert.are.equal(result, 'hello')
  end)

  it('should return (false, error) for invalid input', function()
    local schema = c.string()
    local ok, error_msg = schema:safe_parse(42)
    assert.is_false(ok)
    assert.is_string(error_msg)
    assert.matches('Expected string', error_msg)
  end)

  it('should work with complex schemas', function()
    local user_schema = c.object({
      name = c.string(),
      age = c.integer(),
    })

    -- Valid data
    local ok, result = user_schema:safe_parse({ name = 'Alice', age = 30 })
    assert.is_true(ok)
    assert.are.equal(result.name, 'Alice')
    assert.are.equal(result.age, 30)

    -- Invalid data
    local ok2, error_msg = user_schema:safe_parse({ name = 'Bob' })
    assert.is_false(ok2)
    assert.is_string(error_msg)
    assert.matches('Missing required field', error_msg)
  end)
end)

describe('Schema:ensure()', function()
  it('should not throw error for valid input', function()
    assert.has_no.errors(function()
      c.string():ensure('hello')
    end)
  end)

  it('should throw error for invalid input', function()
    assert.has_error(function()
      c.string():ensure(42)
    end)
  end)

  it('should call error handler when provided and validation fails', function()
    local error_captured = nil

    assert.has_no.errors(function()
      c.integer():ensure('not a number', function(err)
        error_captured = err
      end)
    end)

    assert.is_string(error_captured)
    assert.matches('Expected integer', error_captured)
  end)

  it('should not call error handler when validation succeeds', function()
    local error_captured = nil

    assert.has_no.errors(function()
      c.string():ensure('hello', function(err)
        error_captured = err
      end)
    end)

    assert.are.equal(error_captured, nil)
  end)
end)

describe('integration tests', function()
  it('should handle nested objects', function()
    local schema = c.object({
      user = c.object({
        name = c.string(),
        age = c.integer(),
      }),
    })

    local result = schema:parse({
      user = { name = 'Alice', age = 25 },
    })
    assert.are.equal(result.user.name, 'Alice')
    assert.are.equal(result.user.age, 25)
  end)

  it('should handle union with literals', function()
    local schema = c.object({
      status = c.union({ c.literal('active'), c.literal('inactive') }),
    })

    local result = schema:parse({ status = 'active' })
    assert.are.equal(result.status, 'active')
  end)

  it('should handle array fields', function()
    local schema = c.object({
      tags = c.array(c.string()),
    })

    local result = schema:parse({ tags = { 'admin', 'user' } })
    assert.are.equal(result.tags[1], 'admin')
    assert.are.equal(result.tags[2], 'user')
  end)

  it('should handle optional fields', function()
    local schema = c.object({
      metadata = c.optional(c.table()),
    })

    local result = schema:parse({ metadata = { created = '2023-01-01' } })
    assert.are.equal(result.metadata.created, '2023-01-01')
  end)
end)

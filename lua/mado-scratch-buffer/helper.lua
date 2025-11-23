---TODO: Rename to functions.lua

local M = {}

---Validates `validatee` with `schema`.
---Thrown error handled by `vim.notify()` if thrown.
---@generic T
---@param schema chotto.Schema<T>
function M.ensure(schema, validatee)
  schema:ensure(validatee, function(e)
    vim.notify(e, vim.log.levels.ERROR)
  end)
end

---Creates a readonly table
---@generic K, V
---@param x table<K, V>
---@return table<K, V> --But readonly
function M.readonly(x)
  return setmetatable({}, {
    __index = x,
    __newindex = function(_, key, value)
      error(('The table is readonly. { key = %s, value = %s }'):format(key, value))
    end,
    __metatable = false -- getmetatableを防ぐ
  })
end

---Simular to `readonly()`
---```lua
----- These are same:
---local x = readonly({ value = 10 })
---local y = readonly_value(10)
---```
---@generic T
---@param value T
---@return { value: T }
function M.readonly_value(value)
  return M.readonly({
    value = value,
  })
end

---Gets all buffer names
---@return string[]
function M.get_all_buffer_names()
  local buffer_infos = vim.fn.getbufinfo()
  local buffer_names = {}
  for _, info in ipairs(buffer_infos) do
    table.insert(buffer_names, info.name)
  end
  return buffer_names
end

return M

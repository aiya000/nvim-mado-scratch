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

---Creates a readonly table that denies `rawset()` and `rawget()`
---@param x table
---@return userdata
---@see readonly
function M.readonly(x)
  local proxy = newproxy(true)
  local metatable = getmetatable(proxy)
  metatable.__index = x
  return proxy
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

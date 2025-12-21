local M = {}

---Validates `validatee` with `schema`.
---Thrown error handled by `vim.notify()` if thrown.
---@generic T
---@param schema chotto.Schema<T>
---@param validatee unknown
---@param create_message? fun(error_message: string): string
function M.ensure(schema, validatee, create_message)
  create_message = create_message ~= nil
    and create_message
    or function(e) return e end

  schema:ensure(validatee, function(e)
    vim.notify(create_message(e), vim.log.levels.ERROR)
  end)
end

---@generic T
---@param message string
---@param fallback_value T
---@return T
function M.fallback(message, fallback_value)
  vim.notify(message, vim.log.levels.WARN)
  return fallback_value
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

local M = {}

--- Get all buffer names
--- @return string[] buffer_names List of buffer names
function M.get_all_buffer_names()
  local buffer_infos = vim.fn.getbufinfo()
  local buffer_names = {}
  for _, info in ipairs(buffer_infos) do
    table.insert(buffer_names, info.name)
  end
  return buffer_names
end

--- Check if a value exists in a list
--- @param xs any[] List to search in
--- @param x any Value to search for
--- @return boolean exists True if value exists in list
function M.contains(xs, x)
  for _, value in ipairs(xs) do
    if value == x then
      return true
    end
  end
  return false
end

return M
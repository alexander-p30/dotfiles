local M = {}

M.visit_buffers = function(func)
  for _, buffer in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) then
      func(buffer)
    end
  end
end

M.map = function(table, mapper)
  local list = {}

  for k, v in pairs(table) do
    list[#list + 1] = mapper(k, v)
  end

  return list
end

M.string_ends_with = function(str, suffix)
  local suffix_size = string.len(suffix)
  return string.sub(str, -suffix_size, -1) == suffix
end

local escape_pattern = function(pattern)
  -- Escape special characters in the pattern
  return pattern:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

-- taken form https://stackoverflow.com/a/7615129
M.split_string = function(str, separator)
  if separator == nil then
    separator = "%s"
  else
    separator = escape_pattern(separator)
  end

  local string_parts = {}

  for part in string.gmatch(str, "([^" .. separator .. "]*)") do
    if part ~= "" then table.insert(string_parts, part) end
  end

  return string_parts
end

return M

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

return M

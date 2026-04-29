local M = {}

M.for_each_buffer = function(func)
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

M.string_starts_with = function(str, suffix)
  local suffix_size = string.len(suffix)
  return string.sub(str, 1, suffix_size) == suffix
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

M.table_wrap = function(x)
  if type(x) ~= "table" then
    x = { x }
  end

  return x
end

M.merge_tables = function(table_a, table_b)
  for key, value in pairs(table_b) do
    table_a[key] = value
  end

  return table_a
end

M.open_in_float = function(opts)
  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Calculate floating window size
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Open floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  if opts.run then opts.run() end

  if opts.quit_on then
    -- Optional close key
    vim.keymap.set("n", opts.quit_on, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, silent = true })
  end

  return win
end

return M

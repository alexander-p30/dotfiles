local M = {}

M.test_in_neoterm = function(option)
  if option == 'tn' then
    vim.api.nvim_command('TestNearest')
  elseif option == 'tf' then
    vim.api.nvim_command('TestFile')
  elseif option == 'ts' then
    vim.api.nvim_command('TestSuite')
  elseif option == 'tl' then
    vim.api.nvim_command('TestLast')
  else
    return
  end
  vim.api.nvim_command('Topen')
end

M.lint_in_neoterm = function()
  vim.api.nvim_command('T MIX_ENV=test mix format && mix credo --strict && mix dialyzer')
  vim.api.nvim_command('Topen')
end

M.visit_buffers = function(func)
  for _, buffer in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) then
      func(buffer)
    end
  end
end

return M

local function add_lines_to_term()
  local buf_ft = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), 'filetype')
  if buf_ft == 'neoterm' then
    vim.api.nvim_command('set relativenumber')
    vim.api.nvim_command('set number')
  end
end

local term_group = vim.api.nvim_create_augroup('term_group', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
  group = term_group,
  pattern = 'term:/*neoterm*',
  callback = add_lines_to_term
})

vim.cmd([[
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
]])

vim.cmd([[
  autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>
]])

function apply_function_for_buffer_with_ft(buffer, ft, func)
  local buffer_ft = vim.api.nvim_buf_get_option(buffer, "filetype")
  if buffer_ft == ft then func(buffer) end

  return buffer_ft == ft
end

function delete_filetree_buffer()
  local buffers = vim.api.nvim_list_bufs()
  local delete_buffer = function(b) vim.api.nvim_buf_delete(b, {}) end

  for k, buffer in pairs(buffers) do
    apply_function_for_buffer_with_ft(buffer, "neo-tree", delete_buffer)
  end
end

require("persisted").setup({
  use_git_branch = true,
  autosave = true,
  autoload = true,
  before_save = delete_filetree_buffer,
  telescope = {
    before_source = function()
      local buffers = vim.api.nvim_list_bufs()
      local force_delete_buffer = function(b) vim.api.nvim_buf_delete(b, { force = true }) end

      for k, buffer in pairs(buffers) do
        if not apply_function_for_buffer_with_ft(buffer, "neoterm", force_delete_buffer) then
          vim.api.nvim_buf_delete(buffer, {})
        end
      end
    end,
    after_source = function(session)
      print("Loaded session " .. session.name)
    end,
  },
})

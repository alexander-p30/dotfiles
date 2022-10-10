local util = require('config.functions')

require('persisted').setup({
  use_git_branch = true,
  autosave = true,
  autoload = true,
  on_autoload_no_session = function() vim.notify('No existing session to load.') end,
  before_save = function()
    local delete_buggy_buffers = function(buffer)
      local buffer_ft = vim.api.nvim_buf_get_option(buffer, 'filetype')
      if buffer_ft == 'neo-tree' or buffer_ft == 'packer' then
        vim.api.nvim_buf_delete(buffer, {})
      end
    end

    util.visit_buffers(delete_buggy_buffers)
  end,
  after_save = function() vim.notify('Session saved!') end,
  after_source = function() vim.notify('Session loaded...') end,
  telescope = {
    before_source = function()
      local delete_neoterm_buffer = function(buffer)
        util.apply_function_for_buffer_with_ft(
          buffer,
          'neoterm',
          util.delete_buffer_func(buffer, { force = true })
        )
      end

      util.visit_buffers(delete_neoterm_buffer)
    end,
    after_source = function(session) vim.notify('Loaded session ' .. session.name) end,
  },
})

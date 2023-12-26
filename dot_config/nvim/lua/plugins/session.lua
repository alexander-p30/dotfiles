local util = require('helper.functions')

local sanitize_session_name = function(session)
  -- relative/path/to/folder
  local split_path = util.split_string(session.dir_path, '/')
  local folder = split_path[#split_path]

  return folder .. '@' .. session.branch
end

return {
  'olimorris/persisted.nvim',
  config = function()
    require('persisted').setup({
      use_git_branch = true,
      autosave = true,
      autoload = true,
      on_autoload_no_session = function() vim.notify('No existing session to load.') end,
    })

    local group = vim.api.nvim_create_augroup('PersistedHooks', {})

    local hook_specs = {
      {
        pattern = 'PersistedSavePre',
        callback = function()
          util.for_each_buffer(function(buf)
            local buf_ft = vim.api.nvim_buf_get_option(buf, 'filetype')
            if buf_ft == 'neo-tree' then vim.api.nvim_buf_delete(buf, {}) end
          end)
        end
      },
      { pattern = 'PersistedSavePost', callback = function() vim.notify('Session saved!') end },
      {
        pattern = 'PersistedLoadPost',
        callback = function(session)
          vim.notify('Session loaded! ' .. sanitize_session_name(session.data))
        end
      },
      {
        pattern = 'PersistedTelescopeLoadPre',
        callback = function(_)
          util.for_each_buffer(function(buf)
            local buf_ft = vim.api.nvim_buf_get_option(buf, 'filetype')
            if buf_ft == 'neoterm' then vim.api.nvim_buf_delete(buf, { force = true }) end
          end)
        end
      },
      {
        pattern = 'PersistedTelescopeLoadPost',
        callback = function(session)
          vim.notify('Loaded session ' .. sanitize_session_name(session.data.name))
        end
      }
    }

    for _, hook_spec in pairs(hook_specs) do
      hook_spec.group = group
      vim.api.nvim_create_autocmd({ 'User' }, hook_spec)
    end
  end
}

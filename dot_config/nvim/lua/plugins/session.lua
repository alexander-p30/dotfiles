return {
  'olimorris/persisted.nvim',
  config = function()
    local util = require('helper.functions')

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
          util.visit_buffers(function(b)
            local buf_ft = vim.api.nvim_buf_get_option(b, 'filetype')
            if buf_ft == 'neo-tree' then vim.api.nvim_buf_delete(b, {}) end
          end)
        end
      },
      { pattern = 'PersistedSavePost', callback = function() vim.notify('Session saved!') end },
      {
        pattern = 'PersistedLoadPost',
        callback = function(session)
          vim.notify('Session loaded! ' .. session.data)
        end
      },
      {
        pattern = 'PersistedTelescopeLoadPre',
        callback = function(_)
          util.visit_buffers(function(b)
            local buf_ft = vim.api.nvim_buf_get_option(b, 'filetype')
            if buf_ft == 'neoterm' then vim.api.nvim_buf_delete(b, { force = true }) end
          end)
        end
      },
      {
        pattern = 'PersistedTelescopeLoadPost',
        callback = function(session)
          vim.notify('Loaded session ' .. session.data.name)
        end
      }
    }

    for _, hook_spec in pairs(hook_specs) do
      hook_spec.group = group
      vim.api.nvim_create_autocmd({ 'User' }, hook_spec)
    end
  end
}

local util = require('helper.functions');

local sanitize_session_name = function(session)
  if session == nil then
    return ''
  end

  local branch_separator = '@@'

  -- absolute/but%escaped%path@@branch.nvim
  local name_parts = util.split_string(session.name, branch_separator)
  local path = name_parts[1]
  local branch = name_parts[2]

  -- get folder from path
  local path_parts = util.split_string(path, '/')
  local folder = path_parts[#path_parts]

  if branch then
    return folder .. '@' .. branch
  end

  return folder
end;

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

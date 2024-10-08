return {
  'nvim-lualine/lualine.nvim',
  config = function()
    -- Eviline config for lualine
    -- Author: shadmansaleh
    -- Credit: glepnir
    local lualine = require 'lualine'

    -- Color table for highlights
    -- stylua: ignore
    local colors = {
      bg         = '#181825',
      fg         = '#CDD6F4',
      yellow     = '#F9E2AF',
      cyan       = '#89DCEB',
      darkblue   = '#11111B',
      green      = '#A6E3A1',
      orange     = '#FAB387',
      violet     = '#B4BEFE',
      magenta    = '#CBA6F7',
      blue       = '#89B4FA',
      red        = '#F38BA8',
      gray       = '#464651',
      light_gray = '#8C8C92',
    }

    local conditions = {
      buffer_not_empty = function()
        return vim.fn.empty(vim.fn.expand '%:t') ~= 1
      end,
      hide_in_width = function()
        return vim.fn.winwidth(0) > 80
      end,
      check_git_workspace = function()
        local filepath = vim.fn.expand '%:p:h'
        local gitdir = vim.fn.finddir('.git', filepath .. ';')
        return gitdir and #gitdir > 0 and #gitdir < #filepath
      end,
    }

    -- Config
    local config = {
      options = {
        -- Disable sections and component separators
        component_separators = '',
        section_separators = '',
        theme = {
          -- We are going to use lualine_c an lualine_x as left and
          -- right section. Both are highlighted by c theme .  So we
          -- are just setting default looks o statusline
          normal = { c = { fg = colors.fg, bg = colors.bg } },
          inactive = { c = { fg = colors.fg, bg = colors.bg } },
        },
        globalstatus = true,
      },
      sections = {
        -- these are to remove the defaults
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        -- These will be filled later
        lualine_c = {},
        lualine_x = {},
      },
      inactive_sections = {
        -- these are to remove the defaults
        lualine_a = {},
        lualine_v = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = {},
        lualine_x = {},
      },
      tabline = {
        lualine_c = {},
        lualine_x = {},
      }
    }

    -- Inserts a component in lualine_c at left section
    local function ins_left(component)
      table.insert(config.sections.lualine_c, component)
    end

    local function ins_left_inactive(component)
      table.insert(config.inactive_sections.lualine_c, component)
    end

    local function ins_right_inactive(component)
      table.insert(config.inactive_sections.lualine_x, component)
    end

    -- Inserts a component in lualine_x ot right section
    local function ins_right(component)
      table.insert(config.sections.lualine_x, component)
    end

    local function ins_tab_left(component)
      table.insert(config.tabline.lualine_c, component)
    end

    local function ins_tab_right(component)
      table.insert(config.tabline.lualine_x, component)
    end

    ins_left {
      function()
        return '▊'
      end,
      color = { fg = colors.blue },      -- Sets highlighting of component
      padding = { left = 0, right = 1 }, -- We don't need space before this
    }

    ins_left {
      -- mode component
      function()
        -- auto change color according to neovims mode
        local mode_color = {
          n = colors.red,
          i = colors.green,
          v = colors.blue,
          [''] = colors.blue,
          V = colors.blue,
          c = colors.magenta,
          no = colors.red,
          s = colors.orange,
          S = colors.orange,
          [''] = colors.orange,
          ic = colors.yellow,
          R = colors.violet,
          Rv = colors.violet,
          cv = colors.red,
          ce = colors.red,
          r = colors.cyan,
          rm = colors.cyan,
          ['r?'] = colors.cyan,
          ['!'] = colors.red,
          t = colors.red,
        }
        vim.api.nvim_command('hi! LualineMode guifg=' .. mode_color[vim.fn.mode()] .. ' guibg=' .. colors.bg)
        return ''
      end,
      color = 'LualineMode',
      padding = { right = 1 },
    }

    ins_left {
      -- filesize component
      'filesize',
      cond = conditions.buffer_not_empty,
    }

    ins_left {
      'filename',
      path = 0,
      cond = conditions.buffer_not_empty,
      color = { fg = colors.magenta, gui = 'bold' },
      padding = { left = 1, right = 0 }
    }

    ins_left {
      'diagnostics',
      sources = { 'nvim_diagnostic' },
      symbols = { error = ' ', warn = ' ', info = ' ' },
      diagnostics_color = {
        color_error = { fg = colors.red },
        color_warn = { fg = colors.yellow },
        color_info = { fg = colors.cyan },
      },
    }

    -- -- Insert mid section. You can make any number of sections in neovim :)
    -- -- for lualine it's any number greater then 2
    -- ins_left {
    --   function()
    --     return '%='
    --   end,
    -- }

    ins_right {
      -- Lsp server name .
      function()
        local msg = '-'
        local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
        local clients = vim.lsp.get_clients()
        if next(clients) == nil then
          return msg
        end
        for _, client in ipairs(clients) do
          local filetypes = client.config.filetypes
          if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
            if not (#clients > 1 and client.name == 'efm') then
              return client.name
            end
          end
        end
        return msg
      end,
      icon = ' ',
      color = { fg = colors.light_gray, gui = 'bold' },
    }

    -- Add components to right sections

    ins_right { 'progress', color = { fg = colors.fg, gui = 'bold' } }

    ins_right { 'location' }

    ins_right {
      'filetype',
      fmt = string.upper,
      icons_enabled = true, -- I think icons are cool but Eviline doesn't have them. sigh
      color = { fg = colors.magenta, gui = 'bold' },
    }

    ins_right {
      function()
        return '▊'
      end,
      color = { fg = colors.blue },
      padding = { left = 1 },
    }

    -- Add components to inactive buffer

    ins_left_inactive {
      function()
        return '▊'
      end,
      color = { fg = colors.gray },
      padding = { left = 0, right = 0 }
    }

    ins_left_inactive {
      function()
        return ''
      end,
      color = { fg = colors.gray },
    }


    ins_left_inactive {
      -- filesize component
      'filesize',
      cond = conditions.buffer_not_empty,
      color = { fg = colors.gray }
    }

    ins_left_inactive {
      'filename',
      path = 1,
      cond = conditions.buffer_not_empty,
      color = { fg = colors.light_gray },
    }

    ins_right_inactive { 'progress', color = { fg = colors.gray } }

    ins_right_inactive { 'location', color = { fg = colors.gray } }

    ins_right_inactive {
      'filetype',
      fmt = string.upper,
      icons_enabled = true, -- I think icons are cool but Eviline doesn't have them. sigh
      colored = false,
      color = { fg = colors.gray, gui = 'bold' },
    }

    ins_right_inactive {
      function()
        return '▊'
      end,
      color = { fg = colors.gray },
      padding = { left = 1 },
    }

    -- Add components to tab's left sections

    ins_tab_left {
      'tabs',
      mode = 1,
      tabs_color = {
        active = { fg = colors.red, bg = colors.gray, gui = 'bold' },
      },
    }

    ins_tab_left {
      function()
        return '%='
      end,
    }

    ins_tab_left {
      'filename',
      path = 1,
      cond = conditions.buffer_not_empty,
      color = { fg = colors.magenta, gui = 'bold' },
    }

    -- Add components to tab's right sections

    ins_tab_right {
      'diff',
      -- Is it me or the symbol for modified us really weird
      symbols = { added = '+', modified = '*', removed = '-' },
      diff_color = {
        added = { fg = colors.green },
        modified = { fg = colors.orange },
        removed = { fg = colors.red },
      },
      cond = conditions.hide_in_width,
    }

    ins_tab_right {
      'branch',
      icon = '',
      color = { fg = colors.violet, gui = 'bold' },
      fmt = function(branch_name)
        local max_size = 33
        local ellipsis = '...'

        if string.len(branch_name) > max_size then
          return string.sub(branch_name, 1, max_size - string.len(ellipsis)) .. ellipsis
        end

        return branch_name
      end,
    }

    -- Now don't forget to initialize lualine
    lualine.setup(config)
  end
}

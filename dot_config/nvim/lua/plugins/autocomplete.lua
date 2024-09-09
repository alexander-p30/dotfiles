return {
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'honza/vim-snippets',
      { 'L3MON4D3/LuaSnip',      version = '1.*', build = 'make install_jsregexp' },
      'saadparwaiz1/cmp_luasnip',
      'onsails/lspkind-nvim',
      { 'windwp/nvim-autopairs', config = true }
    },
    config = function()
      local cmp = require('cmp')
      local lspkind = require('lspkind')
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local luasnip = require('luasnip')

      require('luasnip.loaders.from_snipmate').lazy_load()

      cmp.setup({
        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol_text',
            maxwidth = 60,
            before = function(entry, vim_item)
              vim_item.menu = ({
                nvim_lsp = '[LSP]',
                look = '[Dict]',
                buffer = '[Buffer]',
                luasnip = '[LuaSnip]',
                path = '[Path]',
              })[entry.source.name]

              if not vim_item.menu then
                local message = '[USER] Not found in mapped sources: ' .. entry.source.name
                vim.notify(message)
              end

              return vim_item
            end
          })
        },
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.close(),
          ['<C-CR>'] = cmp.mapping(function(_) luasnip.expand_or_jump() end, { 'i', 's' }),
          ['<Tab>'] = cmp.mapping.confirm({ select = true }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        }
      })

      cmp.setup.cmdline('/', {
        sources = {
          { name = 'buffer' }
        }
      })

      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
    end
  },
  {
    'gelguy/wilder.nvim',
    keys = { ':', '/', '?' },
    config = function()
      local wilder = require('wilder')
      wilder.setup({ modes = { ':', '/', '?' } })
      wilder.set_option('renderer', wilder.popupmenu_renderer(
        wilder.popupmenu_border_theme({
          highlights = { border = 'Normal', },
          border = 'rounded',
        })
      ))
    end,
  },
  {
    'github/copilot.vim',
    enabled = function()
      return vim.fn.hostname() == 'Remote-Estevan-Alexander-de-Paula.local'
    end,
    init = function()
      vim.keymap.set('i', '<C-g>', 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false
      })
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
    end,
  }
}

return {
  {
    'hrsh7th/nvim-cmp',
    config = function()
      local cmp = require('cmp')
      local lspkind = require('lspkind')
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')

      cmp.setup({
        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol_text',
            maxwidth = 60, -- prevent the popup from showing more than provided characters

            -- The function below will be called before any actual modifications from lspkind
            -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
            before = function(entry, vim_item)
              vim_item.menu = ({
                    nvim_lsp = '[LSP]',
                    look = '[Dict]',
                    bufferi = '[Buffer]'
                  })[entry.source.name]

              return vim_item
            end
          })
        },
        snippet = {
          expand = function(args)
            vim.fn['UltiSnips#Anon'](args.body)
          end
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs( -4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.close(),
          ['<Tab>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'ultisnips' },
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
    end,
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'SirVer/ultisnips',
      'quangnguyen30192/cmp-nvim-ultisnips',
      'onsails/lspkind-nvim',
      { 'windwp/nvim-autopairs', config = true }
    }
  },
  {
    'gelguy/wilder.nvim',
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
}

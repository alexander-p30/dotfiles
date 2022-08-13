local cmp = require('cmp')
local lspkind = require('lspkind')

vim.cmd([[
  imap <silent><expr> <C-;> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>' 
  " -1 for jumping backwards.
  inoremap <silent> <C-S-;> <cmd>lua require'luasnip'.jump(-1)<Cr>

  snoremap <silent> <C-;> <cmd>lua require('luasnip').jump(1)<Cr>
  snoremap <silent> <C-S-;> <cmd>lua require('luasnip').jump(-1)<Cr>
]])

cmp.setup({
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol', -- show only symbol annotations
      maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)

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
      require('luasnip').lsp_expand(args.body)
    end
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
    ['<Tab>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
  }
})

cmp.setup.cmdline('/', {
  sources = {
    { name = 'buffer' }
  }
})

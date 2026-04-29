return {
  {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = {
      { 'L3MON4D3/LuaSnip',      version = '2.*', build = 'make install_jsregexp' },
      'honza/vim-snippets',
      { 'nvim-mini/mini.pairs', version = '*', config = true },
    },
    opts = {
      snippets = { preset = 'luasnip' },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      cmdline = {
        sources = { 'buffer' },
      },
      keymap = {
        preset = 'none',
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'cancel', 'fallback' },
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<Tab>'] = { 'accept', 'fallback' },
        ['<C-d>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<C-Right>'] = { 'snippet_forward', 'fallback' },
        ['<C-Left>'] = { 'snippet_backward', 'fallback' },
      },
      completion = {
        documentation = { window = { border = 'rounded' } },
        menu = { border = 'rounded' },
      },
    },
    config = function(_, opts)
      require('luasnip.loaders.from_snipmate').lazy_load()
      require('blink.cmp').setup(opts)
    end,
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
    "yetone/avante.nvim",
    enabled = false,
    event = "VeryLazy",
    lazy = false,
    opts = {
      behaviour = {
        auto_apply_diff_after_generation = false,
        auto_suggestions = false
      },
    },
    build = "make",
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
      "saghen/blink.cmp",
      "nvim-tree/nvim-web-devicons",
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  }
}

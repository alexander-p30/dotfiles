return {
  {
    'williamboman/mason-lspconfig.nvim',
    config = function() require('mason-lspconfig').setup({ automatic_installation = true }) end,
    dependencies = {
      {
        'williamboman/mason.nvim',
        cmd = 'Mason',
        config = function() require('mason').setup({ ui = { border = 'rounded' } }) end,
      }
    }
  },
}

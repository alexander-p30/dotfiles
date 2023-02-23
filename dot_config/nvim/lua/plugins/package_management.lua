return {
  {
    'williamboman/mason.nvim',
    config = function() require('mason').setup({ ui = { border = 'rounded' } }) end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    config = function() require('mason-lspconfig').setup({ automatic_installation = true }) end
  }
}

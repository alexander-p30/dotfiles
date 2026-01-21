return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'lukas-reineke/lsp-format.nvim',
    'ray-x/lsp_signature.nvim',
    { 'j-hui/fidget.nvim', config = true },
    'hrsh7th/nvim-cmp'
  },
  config = function()
    local lspconfig = vim.lsp.config

    local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
    function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
      opts = opts or {}
      opts.border = opts.border or 'rounded'
      return orig_util_open_floating_preview(contents, syntax, opts, ...)
    end

    require('lsp-format').setup({})

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(event)
        -- local client = vim.lsp.get_client_by_id(event.data.client_id)
        local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
        local bufnr = event.buf
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        require("lsp-format").on_attach(client, bufnr)

        vim.keymap.set('n', '<leader>li', function() vim.lsp.buf.format({ async = true }) end, bufopts)

        require('lsp_signature').on_attach({ bind = true, handler_opts = { border = 'rounded' } }, bufnr)

        -- Mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
        vim.keymap.set('n', '<C-w>gv', ':vs<CR><cmd>lua vim.lsp.buf.definition()<CR>', bufopts)
        vim.keymap.set('n', '<C-w>gs', ':sp<CR><cmd>lua vim.lsp.buf.definition()<CR>', bufopts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
        vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set('i', '<C-q>', vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, bufopts)
        vim.keymap.set('n', '[e', vim.diagnostic.goto_prev, bufopts)
        vim.keymap.set('n', ']e', vim.diagnostic.goto_next, bufopts)

        -- Workspace stuff
        vim.keymap.set('n', '<leader>lwa', vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set('n', '<leader>lwr', vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set('n', '<leader>lwl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)
      end
    })
  end
}

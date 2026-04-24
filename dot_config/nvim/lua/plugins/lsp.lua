return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    opts = {
      format_on_save = {
        lsp_format = 'fallback',
        timeout_ms = 500,
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'ray-x/lsp_signature.nvim',
      { 'j-hui/fidget.nvim', config = true },
      'saghen/blink.cmp',
    },
    config = function()
      local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = opts.border or 'rounded'
        return orig_util_open_floating_preview(contents, syntax, opts, ...)
      end

      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local bufnr = event.buf
          local bufopts = { noremap = true, silent = true, buffer = bufnr }

          vim.keymap.set('n', '<leader>li',
            function() require('conform').format({ async = true, lsp_format = 'fallback' }) end, bufopts)

          require('lsp_signature').on_attach({ bind = true, handler_opts = { border = 'rounded' } }, bufnr)

          -- Mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
          -- vim.keymap.set('n', '<C-w>gv', ':vs<CR><cmd>lua vim.lsp.buf.definition()<CR>', bufopts)
          -- vim.keymap.set('n', '<C-w>gs', ':sp<CR><cmd>lua vim.lsp.buf.definition()<CR>', bufopts)
          vim.keymap.set('n', '<C-w>gv', ':vs<CR><cmd>lua require("helper.lsp").goto_definition()<CR>', bufopts)
          vim.keymap.set('n', '<C-w>gs', ':sp<CR><cmd>lua require("helper.lsp").goto_definition()<CR>', bufopts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
          vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, bufopts)
          vim.keymap.set('i', '<C-q>', vim.lsp.buf.signature_help, bufopts)
          vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
          -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
          vim.keymap.set('n', 'gd', require('helper.lsp').goto_definition, bufopts)
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

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' } }
          }
        }
      })


      vim.lsp.config('dexter', {
        cmd = { 'dexter', 'lsp' },
        root_markers = { '.dexter.db', '.git', 'mix.exs' },
        filetypes = { 'elixir', 'eelixir', 'heex' },
        init_options = {
          followDelegates = true, -- jump through defdelegate to the target function
          -- stdlibPath = "",      -- override Elixir stdlib path (auto-detected)
          -- debug = false,        -- verbose logging to stderr (view with :LspLog)
        },
      })

      vim.lsp.enable('dexter')
    end
  }
}

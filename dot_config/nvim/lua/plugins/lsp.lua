local util = require('helper.functions')

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'lukas-reineke/lsp-format.nvim',
    'ray-x/lsp_signature.nvim',
    { 'j-hui/fidget.nvim', config = true, tag = 'legacy' },
  },
  config = function()
    local nvim_lsp = require('lspconfig')

    local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
    function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
      opts = opts or {}
      opts.border = opts.border or 'rounded'
      return orig_util_open_floating_preview(contents, syntax, opts, ...)
    end

    require('lsp-format').setup({})

    local function on_attach(client, bufnr)
      local bufopts = { noremap = true, silent = true, buffer = bufnr }

      -- Set up alternative keymap to format file
      if client.name == nvim_lsp.elixirls.name then
        vim.keymap.set('n', '<leader>li', ':Format<CR>',
          { noremap = true, desc = 'Format current buffer with formatter.nvim' })
      else
        vim.keymap.set('n', '<leader>li', function() vim.lsp.buf.format({ async = true }) end, bufopts)
      end

      -- Don't setup lsp_signature_help when in an elixir test-file
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      if not util.string_ends_with(buffer_name, "_test.exs") then
        require('lsp_signature').on_attach({
          bind = true,
          handler_opts = { border = 'rounded' }
        }, bufnr)
      end

      require('lsp-format').on_attach(client)

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
      -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
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

    local function get_ls_cmd(ls)
      local language_servers_dir = vim.fn.stdpath('data') .. '/mason/bin/'
      return language_servers_dir .. ls
    end

    local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

    local function config(ls, ...)
      return { capabilities = capabilities, on_attach = on_attach, cmd = { get_ls_cmd(ls), ... } }
    end

    nvim_lsp.elixirls.setup(config('elixir-ls'))
    nvim_lsp.efm.setup({ filetypes = { 'elixir' }, cmd = { get_ls_cmd('efm-langserver') } })
    nvim_lsp.gopls.setup(config('gopls'))
    nvim_lsp.tsserver.setup(config('typescript-language-server', '--stdio'))
    nvim_lsp.clangd.setup(config('clangd'))
    nvim_lsp.hls.setup(config('haskell-language-server-wrapper', '--lsp'))
    nvim_lsp.rust_analyzer.setup(config('rust-analyzer'))
    nvim_lsp.solargraph.setup(config('solargraph', 'stdio'))
    nvim_lsp.pyright.setup(config('pyright-langserver', '--stdio'))

    nvim_lsp.lua_ls.setup({
      cmd = { get_ls_cmd('lua-language-server') },
      on_attach = on_attach,
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT', },
          diagnostics = { globals = { 'vim' }, },
          workspace = {
            library = {
              vim.api.nvim_get_runtime_file('', true),
              vim.api.nvim_get_runtime_file('/lua/vim/lsp', true),
            },
          },
          telemetry = { enable = false, },
        },
      },
    })
  end
}

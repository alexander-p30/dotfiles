return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'lukas-reineke/lsp-format.nvim',
    'ray-x/lsp_signature.nvim',
    { 'j-hui/fidget.nvim', config = true, tag = 'legacy' },
  },
  config = function()
    local lspconfig = require('lspconfig')

    local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
    function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
      opts = opts or {}
      opts.border = opts.border or 'rounded'
      return orig_util_open_floating_preview(contents, syntax, opts, ...)
    end

    require('lsp-format').setup({})

    local function on_attach(client, buffer)
      local bufopts = { noremap = true, silent = true, buffer = buffer }

      -- Set up alternative keymap to format file
      if client.name == lspconfig.elixirls.name then
        vim.keymap.set('n', '<leader>li', ':Format<CR>',
          { noremap = true, desc = 'Format current buffer with formatter.nvim' })
      else
        vim.keymap.set('n', '<leader>li', function() vim.lsp.buf.format({ async = true }) end, bufopts)
      end

      require('lsp_signature').on_attach({ bind = true, handler_opts = { border = 'rounded' } }, buffer)

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

    lspconfig.efm.setup({ filetypes = { 'elixir' }, cmd = { get_ls_cmd('efm-langserver') } })
    lspconfig.gopls.setup(config('gopls'))
    lspconfig.tsserver.setup(config('typescript-language-server', '--stdio'))
    lspconfig.clangd.setup(config('clangd'))
    lspconfig.hls.setup(config('haskell-language-server-wrapper', '--lsp'))
    lspconfig.rust_analyzer.setup(config('rust-analyzer'))
    lspconfig.solargraph.setup(config('solargraph', 'stdio'))
    lspconfig.pyright.setup(config('pyright-langserver', '--stdio'))

    lspconfig.lua_ls.setup({
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

    -- Setup lexical or elixirls

    local use_elixirls = false
    if use_elixirls then
      lspconfig.elixirls.setup(config('elixir-ls'))
    else
      local configs = require('lspconfig.configs')
      local lexical_config = {
        filetypes = { 'elixir', 'eelixir', 'heex' },
        cmd = { vim.fn.expand('~/Projects/personal/lexical/_build/dev/package/lexical/bin/start_lexical.sh') },
        settings = {},
      }

      if not configs.lexical then
        configs.lexical = {
          default_config = {
            filetypes = lexical_config.filetypes,
            cmd = lexical_config.cmd,
            root_dir = function(fname)
              return lspconfig.util.root_pattern('mix.exs', '.git')(fname) or vim.loop.os_homedir()
            end,
            -- optional settings
            settings = lexical_config.settings,
          },
        }
      end

      lspconfig.lexical.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        root_dir = function(fname)
          return lspconfig.util.root_pattern("mix.exs", ".git")(fname)
        end
      })
    end
  end
}

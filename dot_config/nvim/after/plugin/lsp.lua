local nvim_lsp = require('lspconfig')
local language_servers_dir = vim.fn.stdpath('data') .. '/lsp_servers'

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })

local function on_attach(_, bufnr)
  local function buf_set_keymap(...) vim.keymap.set(...) end

  require('lsp_signature').on_attach({
    bind = true,
    handler_opts = {
      border = "rounded"
    }
  }, bufnr)

  -- Mappings.
  local opts = { noremap = true, silent = true, buffer = true }
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', vim.lsp.buf.declaration, opts)
  buf_set_keymap('n', 'gd', vim.lsp.buf.definition, opts)
  buf_set_keymap('n', '<C-w>gv', ':vs<CR><cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', '<C-w>gs', ':sp<CR><cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', vim.lsp.buf.hover, opts)
  buf_set_keymap('n', 'gi', vim.lsp.buf.implementation, opts)
  buf_set_keymap('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  buf_set_keymap('i', '<C-q>', vim.lsp.buf.signature_help, opts)
  buf_set_keymap('n', '<leader>D', vim.lsp.buf.type_definition, opts)
  buf_set_keymap('n', '<leader>rn', vim.lsp.buf.rename, opts)
  buf_set_keymap('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  buf_set_keymap('n', 'gr', vim.lsp.buf.references, opts)
  buf_set_keymap('n', '<leader>e', vim.diagnostic.open_float, opts)
  buf_set_keymap('n', '[e', vim.diagnostic.goto_prev, opts)
  buf_set_keymap('n', ']e', vim.diagnostic.goto_next, opts)
  buf_set_keymap('n', '<leader>li', function() vim.lsp.buf.format({ async = true }) end, opts)
end

local function config(cmd_path, ...)
  return {
    capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities()),
    on_attach = on_attach,
    cmd = { language_servers_dir .. cmd_path, ... },
  }
end

nvim_lsp.elixirls.setup(config('/elixir/elixir-ls/language_server.sh'))
nvim_lsp.gopls.setup(config('/go/gopls'))
nvim_lsp.tsserver.setup(config('/tsserver/node_modules/typescript-language-server/lib/cli.js', '--stdio'))
nvim_lsp.clangd.setup(config('/clangd/clangd/bin/clangd'))
nvim_lsp.hls.setup(config('/haskell/haskell-language-server-wrapper', '--lsp'))
nvim_lsp.rust_analyzer.setup(config('/rust/rust-analyzer'))

nvim_lsp.sumneko_lua.setup({
  cmd = { language_servers_dir .. '/sumneko_lua/extension/server/bin/lua-language-server' },
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

nvim_lsp.efm.setup({
  filetypes = { 'elixir' },
  cmd = { language_servers_dir .. '/efm/efm-langserver' }
})

local autoformat_fts = { 'ex', 'exs', 'go', 'rs', 'rb', 'erb', 'lua' }
-- Auto-format on save
for _, ft in pairs(autoformat_fts) do
  vim.api.nvim_command('autocmd BufWritePre *.' .. ft .. ' lua vim.lsp.buf.format { timeout_ms = 500 }')
end

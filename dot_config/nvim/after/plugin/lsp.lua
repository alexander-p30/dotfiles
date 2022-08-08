local nvim_lsp = require('lspconfig')
local language_servers_dir = vim.fn.stdpath('data') .. '/lsp_servers'

local function on_attach()
  local function buf_set_keymap(...) vim.keymap.set(...) end

  --     -- Mappings.
  local opts = { noremap = true, silent = true, buffer = true }
  --         -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', '<C-w>gv', ':vs<CR><cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', '<C-w>gs', ':sp<CR><cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('i', '<C-q>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  buf_set_keymap('n', '[e', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']e', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>li', '<cmd>lua vim.lsp.buf.format { async = true } <CR>', opts)
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
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = {
          vim.api.nvim_get_runtime_file('', true),
          vim.api.nvim_get_runtime_file('/lua/vim/lsp', true),
        },
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
})

require 'lsp_signature'.setup({
  bind = true,
  handler_opts = {
    border = 'single'
  },
})

nvim_lsp.efm.setup({
  filetypes = { 'elixir' },
  cmd = { language_servers_dir .. '/efm/efm-langserver' }
})

-- Auto-format on save
vim.api.nvim_command('autocmd BufWritePre *.ex lua vim.lsp.buf.format { timeout_ms = 500 }')
vim.api.nvim_command('autocmd BufWritePre *.exs lua vim.lsp.buf.format { timeout_ms = 500 }')
vim.api.nvim_command('autocmd BufWritePre *.go lua vim.lsp.buf.format { timeout_ms = 500 }')
vim.api.nvim_command('autocmd BufWritePre *.rs lua vim.lsp.buf.format { timeout_ms = 500 }')
vim.api.nvim_command('autocmd BufWritePre *.lua lua vim.lsp.buf.format { timeout_ms = 500 }')

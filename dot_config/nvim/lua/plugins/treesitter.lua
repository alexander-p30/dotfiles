return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    dependencies = {
      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
      }
    },
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup()

      require('nvim-treesitter-textobjects').setup({
        select = { lookahead = true },
      })

      local select = require('nvim-treesitter-textobjects.select')
      vim.keymap.set({ 'x', 'o' }, 'af', function() select.select_textobject('@function.outer') end)
      vim.keymap.set({ 'x', 'o' }, 'if', function() select.select_textobject('@function.inner') end)
      vim.keymap.set({ 'x', 'o' }, 'aa', function() select.select_textobject('@parameter.outer') end)
      vim.keymap.set({ 'x', 'o' }, 'ia', function() select.select_textobject('@parameter.inner') end)
      vim.keymap.set({ 'x', 'o' }, 'ab', function() select.select_textobject('@block.outer') end)
      vim.keymap.set({ 'x', 'o' }, 'ib', function() select.select_textobject('@block.inner') end)

      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
          vim.cmd("syntax on")
        end,
      })

      vim.api.nvim_create_user_command("TSSetup", function()
        vim.notify("Installing treesitter parsers...", vim.log.levels.INFO)

        treesitter.install({
          'elixir', 'heex', 'ruby', 'html', 'javascript', 'c', 'cpp', 'go', 'haskell', 'java',
          'lua', 'bash', 'erlang', 'sql', 'clojure', 'cmake', 'dockerfile', 'fennel', 'http', 'json',
          'json5', 'jsonc', 'make', 'org', 'python', 'rasi', 'typescript', 'tsx', 'yaml'
        })
      end, {})
    end
  },
  {
    'RRethy/nvim-treesitter-endwise',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'ruby', 'elixir', 'eelixir', 'heex', 'lua', 'bash' }
  }
}

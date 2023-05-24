local nnoremap = require('helper.remap').nnoremap

return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add          = { hl = 'GitSignsAdd', text = '▋', numhl = 'GitSignsAddNr', linehl = 'GitSignsAddLn' },
        change       = { hl = 'GitSignsChange', text = '▋', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
        delete       = { hl = 'GitSignsDelete', text = '▋', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
        topdelete    = { hl = 'GitSignsDelete', text = '▋', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
        changedelete = { hl = 'GitSignsChange', text = '▋', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
        untracked    = { hl = 'GitSignsAdd', text = '▋', numhl = 'GitSignsAddNr', linehl = 'GitSignsAddLn' },
      },
      preview_config = { border = 'rounded' },
      current_line_blame = true,
      current_line_blame_formatter = '   <author>, <author_time:%Y/%m/%d %H:%M> • <summary>',
      current_line_blame_opts = { delay = 300 },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        -- Navigation
        nnoremap('<CR>', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr })

        nnoremap('<backspace>', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr })

        -- Actions
        nnoremap('<leader>ghp', gs.preview_hunk, { desc = 'Preview hunk diff under ther cursor' })
        nnoremap('<leader>ghb', function() gs.blame_line { full = true } end, { desc = 'Blame hunk under the cursor' })
      end
    }
  },
  'tpope/vim-fugitive'
}

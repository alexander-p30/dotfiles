-- taken from https://github.com/ThePrimeagen/.dotfiles/blob/master/nvim/.config/nvim/lua/theprimeagen/keymap.lua
local M = {}

local function bind(op, outer_opts)
  local default_opts = { noremap = true }
  outer_opts = outer_opts or default_opts
  for k, v in pairs(default_opts) do
    if outer_opts[k] == nil then outer_opts[k] = v end
  end

  return function(lhs, rhs, opts)
    opts = vim.tbl_extend("force",
      outer_opts,
      opts or {}
    )
    vim.keymap.set(op, lhs, rhs, opts)
  end
end

M.nmap = bind("n", { noremap = false })
M.nnoremap = bind("n")
M.vnoremap = bind("v")
M.xnoremap = bind("x")
M.inoremap = bind("i")
M.tnoremap = bind("t")

return M

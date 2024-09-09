require('config.opts')
require('config.lazy')
require('config.autocmds')
require('config.keymap')

vim.cmd([[
silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)
]])

local colorscheme = 'github_dark'
vim.cmd.colorscheme(colorscheme)

if colorscheme == 'moonfly' then
  vim.cmd.highlight('DiagnosticVirtualTextError guifg=Red')
  vim.cmd.highlight('DiagnosticVirtualTextWarn guifg=Yellow')
  vim.cmd.highlight('DiagnosticVirtualTextInfo guifg=Green')
  vim.cmd.highlight('DiagnosticVirtualTextHint guifg=Blue')
  vim.cmd.highlight('DiagnosticVirtualTextOk guifg=Blue')
end

vim.cmd.highlight('LineNr guifg=#9ca0a4')

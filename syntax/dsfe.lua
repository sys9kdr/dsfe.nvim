if vim.b.current_syntax then return end
vim.b.current_syntax = 'dsfe'

vim.api.nvim_set_hl(0, 'dsfeDirectory', { link = 'Directory' })
vim.cmd.syntax('match dsfeDirectory ".*\\/$"') -- @todo Use nvim_buf_add_highlight()?

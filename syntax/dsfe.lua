if vim.b.current_syntax then return end
vim.b.current_syntax = "dsfe"
vim.api.nvim_set_hl(0, "dsfeDirectory", { link = "Directory", default = true })
vim.fn.matchadd("dsfeDirectory", [[.*/$]])

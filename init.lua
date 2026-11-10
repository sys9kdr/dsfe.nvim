return {
	"sys9kdr/dsfe.nvim",
	config = function()
		vim.g.loaded_netrw = true
		vim.g.loaded_netrwPlugin = true
		vim.g.loaded_netrwSettings = true
		vim.g.loaded_netrwFileHandlers = true
		require("dsfe").setup()
	end,
}
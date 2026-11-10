local dsfe = require("dsfe")
local sep = package.config:sub(1, 1)

local function get_dirname() return vim.api.nvim_buf_get_var(0, "dsfe_dirname") end

local function open() vim.cmd.edit(get_dirname() .. sep .. vim.api.nvim_get_current_line()) end
local function up() vim.cmd.edit(vim.fn.fnamemodify(get_dirname(), ":h")) end
local function home() vim.cmd.edit(vim.uv.os_homedir()) end
local function reload() dsfe.render(0) end
local function toggle_hidden()
	dsfe.config.show_hidden = not dsfe.config.show_hidden
	reload()
end

local keymaps = {
	{ "<Plug>(dsfe-open)", open },
	{ "<Plug>(dsfe-up)", up },
	{ "<Plug>(dsfe-home)", home },
	{ "<Plug>(dsfe-reload)", reload },
	{ "<Plug>(dsfe-toggle-hidden)", toggle_hidden },
}

if dsfe.config.default_keymaps then
	vim.list_extend(keymaps, {
		{ "<CR>", open, true },
		{ "-", up, true },
		{ "~", home, true },
		{ "+", toggle_hidden, true },
		{ "\\\\", reload, true },
	})
end

for _, k in ipairs(keymaps) do
	vim.keymap.set("n", k[1], k[2], { buffer = 0, remap = k[3] })
end

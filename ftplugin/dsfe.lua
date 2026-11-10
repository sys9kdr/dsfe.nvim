local dsfe = require("dsfe")
local a, m, uv, e = vim.api, vim.keymap.set, vim.uv, vim.cmd.edit
local sep = package.config:sub(1, 1)

local function get_dirname() return vim.api.nvim_buf_get_var(0, "dsfe_dirname") end

local keymaps = {
	{ "<Plug>(dsfe-open)", function() e(get_dirname() .. sep .. a.nvim_get_current_line()) end },
	{ "<Plug>(dsfe-up)", function() e(vim.fn.fnamemodify(get_dirname(), ":h")) end },
	{ "<Plug>(dsfe-home)", function() e(uv.os_homedir()) end },
	{ "<Plug>(dsfe-reload)", e },
	{
		"<Plug>(dsfe-toggle-hidden)",
		function()
			dsfe.config.show_hidden = not dsfe.config.show_hidden
			e()
		end,
	},
}

if dsfe.config.default_keymaps then
	vim.list_extend(keymaps, {
		{ "<CR>", "<Plug>(dsfe-open)", { remap = true } },
		{ "-", "<Plug>(dsfe-up)", { remap = true } },
		{ "~", "<Plug>(dsfe-home)", { remap = true } },
		{ "+", "<Plug>(dsfe-toggle-hidden)", { remap = true } },
		{ "\\\\", "<Plug>(dsfe-reload)", { remap = true } },
	})
end

for _, keymap in ipairs(keymaps) do
	local lhs, rhs, opts = keymap[1], keymap[2], keymap[3] or {}
	m("n", lhs, rhs, vim.tbl_extend("force", { buffer = 0 }, opts))
end

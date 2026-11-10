local api, uv, sort = vim.api, vim.uv, table.sort
local buf_set_lines, buf_set_var = api.nvim_buf_set_lines, api.nvim_buf_set_var

local M = {}
M.config = { show_hidden = true, default_keymaps = true }

---@param ev vim.api.keyset.create_autocmd.callback_args
local function init(ev)
	if vim.bo[ev.buf].buftype ~= "" then return end
	local f = uv.fs_scandir(ev.file)
	if not f then return end

	local dirs, files = {}, {} ---@type string[], string[]

	if M.config.show_hidden then
		while true do
			local n, t = uv.fs_scandir_next(f)
			if not n then break end
			if t == "directory" then
				dirs[#dirs + 1] = n .. "/"
			else
				files[#files + 1] = n
			end
		end
	else
		while true do
			local n, t = uv.fs_scandir_next(f)
			if not n then break end
			if n:byte(1) ~= 46 then
				if t == "directory" then
					dirs[#dirs + 1] = n .. "/"
				else
					files[#files + 1] = n
				end
			end
		end
	end

	sort(dirs)
	sort(files)
	vim.list_extend(dirs, files)

	local bo = vim.bo[ev.buf]
	bo.modifiable = true
	buf_set_lines(ev.buf, 0, -1, true, dirs)
	buf_set_var(ev.buf, "dsfe_dirname", ev.file)

	bo.filetype = "dsfe"
	bo.buftype = "nofile"
	bo.bufhidden = "wipe"
	bo.buflisted = false
	bo.swapfile = false
	bo.modified = false
	api.nvim_set_option_value("wrap", false, { scope = "local" })
	api.nvim_set_option_value("cursorline", true, { scope = "local" })
	bo.modifiable = false
end

function M.setup(c)
	if c then M.config = vim.tbl_extend("force", M.config, c) end

	api.nvim_create_autocmd("VimEnter", {
		once = true,
		pattern = "*",
		-- take over from netrw and NERDTree (the latter via upstream dsfe, from mattn/vim-molder)
		callback = function()
			pcall(api.nvim_clear_autocmds, { group = "FileExplorer" })
			pcall(api.nvim_clear_autocmds, { group = "NERDTreeHijackNetrw" })
		end,
	})

	api.nvim_create_autocmd("BufEnter", {
		group = api.nvim_create_augroup("_dsfe_", {}),
		pattern = "*",
		callback = init,
	})
end

return M

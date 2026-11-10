local api, uv = vim.api, vim.uv

local M = { config = { show_hidden = true, default_keymaps = true } }

---(Re)render a directory into an explorer buffer; public for tests and in-place reload (:edit wipes nofile buffers).
---@param buf integer buffer handle, or 0 for the current buffer
---@param path? string directory to list; defaults to the buffer's b:dsfe_dirname
function M.render(buf, path)
	path = path or vim.b[buf].dsfe_dirname
	if not path then return end
	local f = uv.fs_scandir(path)
	if not f then return end
	vim.b[buf].dsfe_dirname = path

	local dirs, files = {}, {} ---@type string[], string[]
	local show_hidden = M.config.show_hidden
	while true do -- no significant difference at 40k entries if hoisting the show_hidden check out of the loop
		local n, t = uv.fs_scandir_next(f)
		if not n then break end
		if show_hidden or n:byte(1) ~= 46 then
			if t == "directory" then
				dirs[#dirs + 1] = n .. "/"
			else
				files[#files + 1] = n
			end
		end
	end

	table.sort(dirs)
	table.sort(files)
	vim.list_extend(dirs, files)

	local bo = vim.bo[buf]
	bo.modifiable = true
	api.nvim_buf_set_lines(buf, 0, -1, true, dirs)
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

---@param ev vim.api.keyset.create_autocmd.callback_args
local function init(ev)
	if vim.bo[ev.buf].buftype ~= "" then return end
	M.render(ev.buf, ev.file)
end

function M.setup(c)
	if c then M.config = vim.tbl_extend("force", M.config, c) end

	api.nvim_create_autocmd("VimEnter", {
		once = true,
		pattern = "*",
		callback = function() -- take over from netrw and NERDTree (from mattn/vim-molder)
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

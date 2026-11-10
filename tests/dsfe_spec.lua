local api = vim.api

local passed, failed = 0, 0

local function assert_eq(actual, expected, msg)
	if actual ~= expected then
		error(string.format("FAIL: %s\n  expected: %s\n  actual:   %s", msg, tostring(expected), tostring(actual)))
	end
end

local function assert_true(val, msg)
	if not val then error(string.format("FAIL: %s\n  expected truthy, got: %s", msg, tostring(val))) end
end

local function describe(name, fn)
	print("\n== " .. name .. " ==")
	fn()
end

local function it(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
		print("  ✓ " .. name)
	else
		failed = failed + 1
		print("  ✗ " .. name .. ": " .. err)
	end
end

describe("setup", function()
	it("returns module", function()
		local dsfe = require("dsfe")
		dsfe.setup()
		assert_true(dsfe.config ~= nil, "config exists")
	end)

	it("creates augroup", function()
		local ok = pcall(api.nvim_get_autocmds, { group = "_dsfe_" })
		assert_true(ok, "augroup _dsfe_ exists")
	end)
end)

describe("directory opening", function()
	local tmpdir = vim.uv.os_tmpdir() .. "/dsfe_test_" .. tostring(vim.uv.hrtime())
	vim.uv.fs_mkdir(tmpdir, 493)
	vim.uv.fs_mkdir(tmpdir .. "/subdir", 493)
	local fd = vim.uv.fs_open(tmpdir .. "/file.txt", "w", 420)
	if fd then vim.uv.fs_close(fd) end

	it("opens directory buffer", function()
		api.nvim_command("edit " .. tmpdir)
		assert_eq(vim.bo.filetype, "dsfe", "filetype is dsfe")
		assert_eq(vim.bo.buftype, "nofile", "buftype is nofile")
		assert_eq(vim.bo.bufhidden, "wipe", "bufhidden is wipe")
		assert_true(not vim.bo.buflisted, "buflisted is false")
	end)

	it("lists files and dirs", function()
		local lines = api.nvim_buf_get_lines(0, 0, -1, false)
		local has_subdir = false
		local has_file = false
		for _, l in ipairs(lines) do
			if l == "subdir/" then has_subdir = true end
			if l == "file.txt" then has_file = true end
		end
		assert_true(has_subdir, "contains subdir/")
		assert_true(has_file, "contains file.txt")
	end)

	it("has keymaps", function()
		local keymaps = api.nvim_buf_get_keymap(0, "n")
		local has_cr = false
		for _, km in ipairs(keymaps) do
			if km.lhs == "<CR>" then has_cr = true end
		end
		assert_true(has_cr, "has <CR> mapping")
	end)

	-- cleanup
	vim.uv.fs_unlink(tmpdir .. "/file.txt")
	vim.uv.fs_rmdir(tmpdir .. "/subdir")
	vim.uv.fs_rmdir(tmpdir)
end)

describe("show_hidden config", function()
	local tmpdir = vim.uv.os_tmpdir() .. "/dsfe_hidden_test_" .. tostring(vim.uv.hrtime())
	vim.uv.fs_mkdir(tmpdir, 493)
	local fd = vim.uv.fs_open(tmpdir .. "/.hidden", "w", 420)
	if fd then vim.uv.fs_close(fd) end

	it("shows hidden by default", function()
		require("dsfe").setup({ show_hidden = true })
		api.nvim_command("edit " .. tmpdir)
		local lines = api.nvim_buf_get_lines(0, 0, -1, false)
		local has_hidden = false
		for _, l in ipairs(lines) do
			if l == ".hidden" then has_hidden = true end
		end
		assert_true(has_hidden, "contains .hidden")
	end)

	it("hides hidden when false", function()
		require("dsfe").setup({ show_hidden = false })
		api.nvim_command("edit " .. tmpdir)
		local lines = api.nvim_buf_get_lines(0, 0, -1, false)
		local has_hidden = false
		for _, l in ipairs(lines) do
			if l == ".hidden" then has_hidden = true end
		end
		assert_true(not has_hidden, "does not contain .hidden")
	end)

	vim.uv.fs_unlink(tmpdir .. "/.hidden")
	vim.uv.fs_rmdir(tmpdir)
end)

describe("render", function()
	local tmpdir = vim.uv.os_tmpdir() .. "/dsfe_render_test_" .. tostring(vim.uv.hrtime())
	vim.uv.fs_mkdir(tmpdir, 493)
	local fd = vim.uv.fs_open(tmpdir .. "/a.txt", "w", 420)
	if fd then vim.uv.fs_close(fd) end

	local function has_line(lines, want)
		for _, l in ipairs(lines) do
			if l == want then return true end
		end
		return false
	end

	it("re-renders after the directory changes", function()
		require("dsfe").setup({ show_hidden = true })
		api.nvim_command("edit " .. tmpdir)
		local fd2 = vim.uv.fs_open(tmpdir .. "/b.txt", "w", 420)
		if fd2 then vim.uv.fs_close(fd2) end
		require("dsfe").render(0)
		local lines = api.nvim_buf_get_lines(0, 0, -1, false)
		assert_true(has_line(lines, "a.txt"), "contains a.txt")
		assert_true(has_line(lines, "b.txt"), "contains b.txt after render")
		assert_eq(vim.bo.buftype, "nofile", "still nofile")
		assert_true(not vim.bo.modifiable, "still not modifiable")
	end)

	it("applies show_hidden toggle in place", function()
		local fd3 = vim.uv.fs_open(tmpdir .. "/.secret", "w", 420)
		if fd3 then vim.uv.fs_close(fd3) end
		require("dsfe").config.show_hidden = false
		require("dsfe").render(0)
		local lines = api.nvim_buf_get_lines(0, 0, -1, false)
		assert_true(not has_line(lines, ".secret"), "hides .secret when show_hidden is false")
		assert_true(has_line(lines, "a.txt"), "still lists a.txt")
	end)

	it("is a no-op on a buffer without dsfe_dirname", function()
		api.nvim_command("enew")
		require("dsfe").render(0)
		assert_eq(vim.bo.buftype, "", "blank buffer untouched")
	end)

	vim.uv.fs_unlink(tmpdir .. "/a.txt")
	vim.uv.fs_unlink(tmpdir .. "/b.txt")
	vim.uv.fs_unlink(tmpdir .. "/.secret")
	vim.uv.fs_rmdir(tmpdir)
end)

describe("non-directory buffer", function()
	local tmpfile = vim.uv.os_tmpdir() .. "/dsfe_nodir_test_" .. tostring(vim.uv.hrtime())
	local fd = vim.uv.fs_open(tmpfile, "w", 420)
	if fd then vim.uv.fs_close(fd) end

	it("does not modify normal file buffer", function()
		api.nvim_command("edit " .. tmpfile)
		assert_eq(vim.bo.filetype, "", "filetype is empty")
		assert_eq(vim.bo.buftype, "", "buftype is empty")
	end)

	vim.uv.fs_unlink(tmpfile)
end)

describe("blank buffer", function()
	it("does not modify blank buffer", function()
		api.nvim_command("enew")
		assert_eq(vim.bo.filetype, "", "filetype is empty")
		assert_eq(vim.bo.buftype, "", "buftype is empty")
	end)
end)

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
	vim.cmd("cq")
else
	vim.cmd("q")
end

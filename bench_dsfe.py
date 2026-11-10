#!/usr/bin/env python3
"""Benchmark for dsfe.nvim - measures directory listing performance via nvim --headless."""

import subprocess
import os
import tempfile
import shutil
import statistics
import sys
import argparse

DSFE_PATH = os.path.dirname(os.path.abspath(__file__))

LUA_CODE = r"""
local uv = vim.uv
local api = vim.api

local function run(dirname)
	local s = uv.fs_stat(dirname)
	if not s or s.type ~= "directory" then return 0 end
	local f = uv.fs_scandir(dirname)
	if not f then return 0 end

	local dirs, files = {}, {}
	while true do
		local n, t = uv.fs_scandir_next(f)
		if not n then break end
		if t == "directory" then
			dirs[#dirs + 1] = n .. "/"
		else
			files[#files + 1] = n
		end
	end

	table.sort(dirs)
	table.sort(files)
	vim.list_extend(dirs, files)

	local buf = api.nvim_create_buf(false, true)
	local bo = vim.bo[buf]
	bo.modifiable = true
	api.nvim_buf_set_lines(buf, 0, -1, true, dirs)
	api.nvim_buf_set_var(buf, "dsfe_dirname", dirname)
	bo.filetype = "dsfe"
	bo.buftype = "nofile"
	bo.bufhidden = "wipe"
	bo.buflisted = false
	bo.swapfile = false
	bo.modified = false
	api.nvim_set_option_value("wrap", false, { scope = "local" })
	api.nvim_set_option_value("cursorline", true, { scope = "local" })
	bo.modifiable = false
	api.nvim_buf_delete(buf, { force = true })
	return #dirs
end

local dirname = os.getenv("DSFE_BENCH_DIR")
local rounds = tonumber(os.getenv("DSFE_BENCH_ROUNDS")) or 10

if not dirname then
	io.write("ERROR: DSFE_BENCH_DIR not set\n")
	vim.cmd("qa!")
end

local results = {}
for i = 1, rounds do
	collectgarbage("collect")
	local t0 = uv.hrtime()
	run(dirname)
	local elapsed_ms = (uv.hrtime() - t0) / 1e6
	results[i] = elapsed_ms
end

-- Output results as comma-separated values
local out = {}
for i = 1, #results do
	out[i] = string.format("%.3f", results[i])
end
io.write(table.concat(out, ",") .. "\n")
vim.cmd("qa!")
"""

def create_test_dir(n_dirs, n_files):
	tmpdir = tempfile.mkdtemp(prefix="dsfe_bench_")
	for i in range(n_dirs):
		os.makedirs(os.path.join(tmpdir, f"dir_{i:06d}"))
	for i in range(n_files):
		open(os.path.join(tmpdir, f"file_{i:06d}"), "w").close()
	return tmpdir

def run_bench(dirname, rounds):
	lua_fd, lua_path = tempfile.mkstemp(suffix=".lua", prefix="dsfe_bench_")
	with os.fdopen(lua_fd, "w") as f:
		f.write(LUA_CODE)

	env = os.environ.copy()
	env["DSFE_BENCH_DIR"] = dirname
	env["DSFE_BENCH_ROUNDS"] = str(rounds)

	cmd = [
		"nvim", "--headless", "--clean",
		"--cmd", f"set rtp+={DSFE_PATH}",
		"-c", f"source {lua_path}",
	]

	result = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=60)
	os.unlink(lua_path)

	if result.returncode != 0:
		print(f"Error: {result.stderr.strip()}", file=sys.stderr)
		return []

	try:
		return [float(x) for x in result.stdout.strip().split(",") if x]
	except ValueError:
		print(f"Parse error: {result.stdout.strip()}", file=sys.stderr)
		return []

def main():
	parser = argparse.ArgumentParser(description="Benchmark dsfe.nvim")
	parser.add_argument("-n", type=int, default=1000, help="Number of dirs and files")
	parser.add_argument("-r", "--rounds", type=int, default=10, help="Number of rounds")
	args = parser.parse_args()

	print(f"Creating test directory ({args.n} dirs, {args.n} files)...")
	tmpdir = create_test_dir(args.n, args.n)

	try:
		print(f"Running benchmark ({args.rounds} rounds)...")
		results = run_bench(tmpdir, args.rounds)

		if not results:
			print("No valid results")
			sys.exit(1)

		print(f"\nResults ({len(results)} rounds):")
		print(f"  Mean:   {statistics.mean(results):.3f} ms")
		print(f"  Median: {statistics.median(results):.3f} ms")
		if len(results) > 1:
			print(f"  StdDev: {statistics.stdev(results):.3f} ms")
			print(f"  Min:    {min(results):.3f} ms")
			print(f"  Max:    {max(results):.3f} ms")
	finally:
		shutil.rmtree(tmpdir)
		print(f"\nCleaned up test directory")

if __name__ == "__main__":
	main()

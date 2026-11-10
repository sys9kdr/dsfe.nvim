.PHONY: lint pretty measure_startup_time bench test

lint:
	luacheck .

pretty:
	stylua .

# Measure the effects of only this plugin.
measure_startup_time:
	vim-startuptime --vimpath nvim -- \
        -u NORC \
        --cmd "set nocompatible runtimepath+=$(abspath .)" \
        -c "filetype plugin indent on" \
        > startuptime$$(date +%Y%m%d_%H%M%S).log

bench:
	nvim --headless -u NONE -c "set rtp+=$(abspath .)" -c "lua require('dsfe_bench').run({n=10000, rounds=5})" -c "q"

test:
	nvim --headless -u tests/minimal_init.vim -c "luafile tests/dsfe_spec.lua"

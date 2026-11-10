.PHONY: lint pretty measure_startup_time test

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


test:
	nvim --headless -u tests/minimal_init.vim -c "luafile tests/dsfe_spec.lua"

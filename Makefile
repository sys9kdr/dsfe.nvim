.PHONY: lint pretty measure_startup_time

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

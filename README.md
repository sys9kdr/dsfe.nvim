# dsfe.nvim - Dim simple file explorer

A minimal file explorer plugin for Neovim.

* Version: Pre-release. Under development, so there may be BREAKING CHANGES.
* Target: nvim v0.9+

## Features

- **Minimalist Design**: Keep your Neovim environment clutter-free with a simple and unobtrusive file explorer.
- **Zero Dependencies**: dsfe.nvim requires no external packages or libraries, ensuring a seamless installation process.
- **Effortless Usage**: Start exploring and managing your files and directories within Neovim without the need for extensive configuration. You can move cursor with `hjkl` and open file/dir with `<CR>`.

## Installation

You can easily install `dsfe.nvim` using your favorite Neovim plugin manager. Here's an example using [Lazy.nvim](https://github.com/folke/lazy.nvim#%EF%B8%8F-configuration):

1. Add the following line to your Neovim configuration file (typically `~/.config/nvim/init.lua`):

```lua
require("lazy").setup({
    "sys9kdr/dsfe.nvim",
    config = function()
        require('dsfe').setup()
    end
})
```

2. Restart Neovim.

3. Run `:Lazy check` to install the plugin.

4. You're all set! You can now use dsfe.nvim by invoking the file explorer with:

```vim
:e .
```

Use the standard Neovim navigation keys (`h`, `j`, `k`, `l`) to move around, and press `Enter` to open files or directories.

### Note: Disable Netrw

dsfe.nvim disables some Netrw functionalities, so you don't need to disable Netrw manually. However, for a better experience, it is recommended to fully disable it using the following settings in init.lua.

```lua
-- in init.lua
vim.g.loaded_netrw = true
vim.g.loaded_netrwPlugin = true
vim.g.loaded_netrwSettings = true
vim.g.loaded_netrwFileHandlers = true
```

## Keymappings

* `<CR>` on file: Open the file on existing Vim. `<Plug>(dsfe-open)`
* `<CR>` on directory: Go to the directory. `<Plug>(dsfe-open)`
* `-`: Go up parent directory. `<Plug>(dsfe-up)`
* `~`: Go to home directory. `<Plug>(dsfe-home)`
* `+`: Toggle show hidden files. `<Plug>(dsfe-toggle-hidden)`
* `\\`: Reload. `<Plug>(dsfe-reload)`

## Customize

```lua
vim.g.dsfe_show_hidden = true -- show hidden file. default `true`.
```

## Contributing

We welcome and encourage your contributions! Please feel free to submit any issues you encounter or create pull requests for improvements. We appreciate your input! 🚀

## License

[Apache v2](LICENSE).

## Credits

This plugin is heavily inspired from [vim-molder](https://github.com/mattn/vim-molder) and [lir.nvim](https://github.com/tamago324/lir.nvim).


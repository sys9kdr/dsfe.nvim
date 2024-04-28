---@meta types

-- https://github.com/neovim/neovim/blob/924a7ef8bb3b74eccbffd48bc1a283d3867b8119/runtime/lua/vim/_meta/api.lua
-- neovim has a doc for Autocommand callback events but no type info.

---@class AutocommandCallbackEvents This table describes the parameters
--- passed to an autocommand callback function when using `nvim_create_autocmd()`.
---@field id number Autocommand ID.
---@field event string Name of the triggered event. Refer to `autocmd-events` for event names.
---@field group number|nil Autocommand group ID, if applicable.
---@field match string Expanded value of `<amatch>`.
---@field buf number Expanded value of `<abuf>`.
---@field file string Expanded value of `<afile>`.
---@field data any Arbitrary data passed from `nvim_exec_autocmds()`.

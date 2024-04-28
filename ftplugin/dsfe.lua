local map = vim.keymap.set
local uv = vim.uv or vim.loop

local sep = package.config:sub(1, 1) -- Get the path separator based on Lua's configuration

-- Get current dir of dsfe from dsfe_event_val.
local function ged_dir_from_event()
  return vim.api.nvim_buf_get_var(0, 'dsfe_event_val').file
end

local function nmap_buf_if_nomap(lhs, rhs)
  -- use nvim_get_keymap/nvim_buf_get_keymap?
  if vim.fn.hasmapto(rhs) == 0 then
    map('n', lhs, rhs, { buffer = 0, remap = true })
  end
end

map('n', '<Plug>(dsfe-open)', '', {
  buffer = 0,
  callback = function()
    vim.cmd.edit(ged_dir_from_event() .. sep .. vim.api.nvim_get_current_line())
  end,
})

map('n', '<Plug>(dsfe-up)', '', {
  buffer = 0,
  callback = function()
    vim.cmd.edit(vim.fn.fnamemodify(ged_dir_from_event(), ':h'))
  end,
})

map('n', '<Plug>(dsfe-home)', '', {
  buffer = 0,
  callback = function()
    vim.cmd.edit(uv.os_homedir())
  end,
})

map('n', '<Plug>(dsfe-reload)', '', {
  buffer = 0,
  callback = vim.cmd.edit,
})

map('n', '<Plug>(dsfe-toggle-hidden)', '', {
  buffer = 0,
  callback = function()
    vim.g.dsfe_show_hidden = not vim.g.dsfe_show_hidden
    vim.cmd.edit()
  end,
})

-- inspired from vim-molder
nmap_buf_if_nomap('<CR>', '<Plug>(dsfe-open)')
nmap_buf_if_nomap('-', '<Plug>(dsfe-up)')
nmap_buf_if_nomap('~', '<Plug>(dsfe-home)')
nmap_buf_if_nomap('+', '<Plug>(dsfe-toggle-hidden)')
nmap_buf_if_nomap('\\\\', '<Plug>(dsfe-reload)')

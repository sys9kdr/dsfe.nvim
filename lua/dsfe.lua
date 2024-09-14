--(c)2024 sys9kdr Apache v2

---@class FileInfo
---@field name string The filename.
---@field is_dir boolean Indicates whether it is a directory or not.

return {
  ---@type fun(opt: { show_hidden: boolean }?): nil
  setup = function(opt)
    -- Primiarity: show_hidden(arg) > vim.g.dsfe_show_hidden(already set) > true(default value)
    if opt and opt.show_hidden ~= nil then
      vim.g.dsfe_show_hidden = opt.show_hidden
    elseif vim.g.dsfe_show_hidden == nil then
      vim.g.dsfe_show_hidden = true
    end

    local uv, setl = vim.uv or vim.loop,
        function(name, value) vim.api.nvim_set_option_value(name, value, { scope = 'local' }) end

    ---@param file_list FileInfo[]
    ---@return string[]
    local function get_names(file_list)
      local t = {}
      for i, e in ipairs(file_list) do
        t[i] = e.name
      end
      return t
    end

    -- Sort with directory/file and their name.
    ---@type fun(lhs: FileInfo, rhs:FileInfo): boolean
    local function file_sort(lhs, rhs)
      if lhs.is_dir ~= rhs.is_dir then
        return lhs.is_dir
      else
        return lhs.name < rhs.name
      end
    end

    ---@type fun(name: string, filetype: string): FileInfo
    local function convert_to_fileinfo(name, filetype)
      return filetype == 'directory' and { name = name .. '/', is_dir = true }
        or { name = name, is_dir = false }
    end

    -- Initialize the dsfe buffer with the provided event.
    ---@type fun(ev: AutocommandCallbackEvents): nil
    local function init(ev)
      local f, err = uv.fs_scandir(ev.file) --[[@as uv.uv_fs_t ]]
      if err then
        error('Error scanning directory:' .. err)
      end

      local files = {} ---@type FileInfo[]
      local name, filetype = uv.fs_scandir_next(f)

      if vim.g.dsfe_show_hidden then
        while name do
          files[#files + 1] = convert_to_fileinfo(name, filetype)
          name, filetype = uv.fs_scandir_next(f)
        end
      else
        while name do
          if name:sub(1, 1) ~= '.' then
            files[#files + 1] = convert_to_fileinfo(name, filetype)
          end
          name, filetype = uv.fs_scandir_next(f)
        end
      end

      setl('modifiable', true)
      setl('filetype', 'dsfe')

      table.sort(files, file_sort)
      vim.api.nvim_buf_set_lines(0, 0, -1, true, get_names(files))
      vim.api.nvim_buf_set_var(0, 'dsfe_event_val', ev)

      setl('buftype', 'nofile')
      setl('bufhidden', 'unload')
      setl('buflisted', false)
      setl('swapfile', false)
      setl('modifiable', false)
      setl('modified', false)
      setl('wrap', false)
      setl('cursorline', true)
    end

    vim.api.nvim_create_augroup('_dsfe_', { clear = true })
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      group = '_dsfe_',
      pattern = '*',
      callback = function()
        -- from github.com/mattn/vim-molder/blob/f9d5c8113fe2ea977516652be03f79ec0d35bb68/plugin/molder.vim#L6C1-L13C12
        -- Using pcall without the return value, which is not recommended
        pcall(vim.api.nvim_clear_autocmds, { group = 'FileExplorer' })
        pcall(vim.api.nvim_clear_autocmds, { group = 'NERDTreeHijackNetrw' })
      end,
    })
    vim.api.nvim_create_autocmd('BufEnter', {
      group = '_dsfe_',
      pattern = '*',
      callback = init,
    })
  end,
}

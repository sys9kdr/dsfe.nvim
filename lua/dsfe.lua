--(c)2024 sys9kdr Apache v2

return {
  ---@type fun(opt: { show_hidden: boolean }?): nil
  setup = function(opt)
    -- vim.g.dsfe_show_hidden is not a user configuration variable; it controls the visibility of hidden files in the global status.
    vim.g.dsfe_show_hidden = opt and opt.show_hidden or false

    local api, uv = vim.api, vim.uv or vim.loop
    local function setl(name, value)
      api.nvim_set_option_value(name, value, { scope = 'local' })
    end

    -- Sort with directory/file and their name.
    ---@type fun(lhs: FileInfo, rhs: FileInfo): boolean
    local function file_sort(lhs, rhs)
      if lhs.is_dir ~= rhs.is_dir then
        return lhs.is_dir
      else
        return lhs.display_name < rhs.display_name
      end
    end

    ---@type fun(name: string, filetype: string): FileInfo
    local function convert_to_fileinfo(name, filetype)
      local is_dir = filetype == 'directory'
      return { display_name = is_dir and name .. '/' or name, is_dir = is_dir }
    end

    -- Initialize the dsfe buffer with the provided event.
    ---@type fun(ev: AutocommandCallbackEvents): nil
    local function init(ev)
      local f, err = uv.fs_scandir(ev.file) --[[@as uv.uv_fs_t ]]
      if err then return end

      local files = {} ---@type FileInfo[]
      local name, filetype = uv.fs_scandir_next(f)

      if vim.g.dsfe_show_hidden then
        while name do
          files[#files + 1] = convert_to_fileinfo(name, filetype)
          name, filetype = uv.fs_scandir_next(f)
        end
      else
        while name do
          if name:byte(1) ~= 46 then
            files[#files + 1] = convert_to_fileinfo(name, filetype)
          end
          name, filetype = uv.fs_scandir_next(f)
        end
      end

      setl('modifiable', true)
      setl('filetype', 'dsfe')

      local names = {} ---@type string[]
      for i = 1, #files do
        names[i] = files[i].display_name
      end

      table.sort(files, file_sort)
      api.nvim_buf_set_lines(0, 0, -1, true, names)
      api.nvim_buf_set_var(0, 'dsfe_event_val', ev)

      setl('buftype', 'nofile')
      setl('bufhidden', 'unload')
      setl('buflisted', false)
      setl('swapfile', false)
      setl('modifiable', false)
      setl('modified', false)
      setl('wrap', false)
      setl('cursorline', true)
    end

    local id = api.nvim_create_augroup('_dsfe_', { clear = true })
    api.nvim_create_autocmd('VimEnter', {
      once = true,
      group = id,
      pattern = '*',
      callback = function()
        -- from mattn/vim-molder
        pcall(api.nvim_clear_autocmds, { group = 'FileExplorer' })
        pcall(api.nvim_clear_autocmds, { group = 'NERDTreeHijackNetrw' })
      end,
    })
    api.nvim_create_autocmd('BufEnter', {
      group = id,
      pattern = '*',
      callback = init,
    })
  end,
}

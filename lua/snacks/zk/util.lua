local uv = vim.loop
local zk = require("snacks.zk")

local M = {}

M.picker = { -- wrapper functions for @snacks.Picker class
  ---Get zk picker
  ---@return snacks.Picker?
  get_picker = function()
    return Snacks.picker.get({ source = "zk" })[1]
  end,

  ---Get cwd (Useful when ctx.filter.cwd or picker.cwd is not available)
  ---@return string?
  get_cwd = function()
    local picker = M.picker.get_picker()
    if picker then
      return picker.cwd(picker)
    end
  end,

  ---Focus on pickers window
  ---@param win string? "input"|"list"|"preview"
  ---@param opts? {show?: boolean}
  focus = function(win, opts)
    local picker = M.picker.get_picker()
    if picker then
      return picker:focus(win, opts)
    end
  end,
}

M.win = {
  ---@param text string
  ---@param title? string
  ---@param opts? table
  show_popup = function(text, title, opts)
    local lines = vim.split(text, "\n", { plain = true })

    local width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    local height = #lines

    width = math.min(width + 4, math.floor(vim.o.columns * 0.9))
    height = math.min(height + 2, math.floor(vim.o.lines * 0.8))

    local winid = vim.api.nvim_get_current_win()
    local cfg = vim.api.nvim_win_get_config(winid)
    local zindex = (cfg.zindex or 50) + 1

    local defaults = {
      text = lines,
      title = title or nil,
      title_pos = "center",
      relative = "editor",
      position = "float",
      border = "rounded", -- TODO: Get these opts from Snacks defaults
      minimal = true,
      fixbuf = true,
      show = true,
      enter = true,
      focusable = true,
      width = width,
      height = height,
      zindex = zindex + 1,
      wo = {
        wrap = false,
        spell = false,
        statuscolumn = " ",
        conceallevel = 0,
      },
      scratch_ft = "snacks_zk_info",
      keys = {
        q = "close",
        ["<esc>"] = "close",
      },
    }
    opts = vim.tbl_deep_extend("force", defaults, opts or {})
    Snacks.win(opts)
  end,
}

M.zk = { -- wrapper functions for zk-nvim
  ---Get zk notebook path
  ---@return string?
  get_notebook_path = function()
    local path = require("zk.util").notebook_root(M.picker.get_cwd() or vim.fn.getcwd())
    return path
  end,

  ---Returns true if the path is inside the zk, or equal to it
  ---@param path string
  ---@return boolean
  in_zk_dir = function(path)
    local notebook_path = M.zk.get_notebook_path()
    if not notebook_path then
      return false
    end
    notebook_path = vim.fs.normalize(notebook_path)
    path = vim.fs.normalize(path)
    return M.in_dir(path, notebook_path)
  end,
}

---Get a sort key (part)
---(e.g.
---  [!+_]visible_dir
---  [!._].hidden_dir
---  [#+@]file_with_zk
---  [#+_]file_not_zk
---  [#._].hidden_file
---directories are always considered as none-zk.
---@param part string
---@param is_last boolean
---@reaturn string
local function get_sort_key_part(part, entry, is_last)
  local hidden = part:sub(1, 1) == "."
  local kind = (is_last and not entry.dir) and "#" or "!" -- "!":directories -> "#":files
  local visibility = not hidden and "+" or "." -- "+":visible -> ".":hidden
  local title = is_last and not entry.dir and entry.zk and (entry.zk.title or entry.zk.metadata and entry.zk.metadata.title)

  local has_title = (not entry.dir and is_last and entry.zk and title) and "@" or "_" -- "@":has title -> "_":no title
  local name = title or part
  return string.format("[%s%s%s]%s", kind, visibility, has_title, name)
end

---Get a hierarchical sort key based on path
---@param entry snacks.picker.explorer.Node|snacks.picker.explorer.Item
---@param root string?
---@return string
function M.get_sort_key(entry, root)
  local path = entry.file or entry.path -- fallback Node -> Item
  path = uv.fs_realpath(path) or path
  -- if root then -- DEBUG: This disorderes the sort
  --   if path:sub(1, #root) == root then
  --     path = path:sub(#root + 2) -- +2 removes "/" too
  --   end
  -- end
  local parts = vim.split(path, "/", { trimempty = true })

  local sort_list = {}
  for i, name in ipairs(parts) do
    table.insert(sort_list, get_sort_key_part(name, entry, (i == #parts)))
  end

  return table.concat(sort_list)
end

---Return sort function : copied from `lua/snacks/picker/config/init.lua: M.sort()`
---Use custom default() in `lua/snacks/zk/sort.lua` instead
---@param opts snacks.picker.Config
function M.get_sorter(opts)
  local sort = opts.sort or require("snacks.zk.sort").default()
  if type(sort) == "table" then
    return require("snacks.zk.sort").default(sort)
  elseif type(sort) == "function" then
    return sort
  end
end

---@param hl_list table{string, vim.api.keyset.highlight}
function M.set_highlights(hl_list)
  for hl_name, hl in pairs(hl_list) do
    vim.api.nvim_set_hl(0, hl_name, hl)
  end
end

---Returns true if the child is inside the parent dir
---@param dir string
---@param path string
---@return boolean
function M.in_dir(path, dir)
  dir = vim.fs.normalize(dir)
  path = vim.fs.normalize(path)
  return path == dir or path:find(dir .. "/", 1, true) == 1
end

return M

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
    return path == notebook_path or path:find(notebook_path .. "/", 1, true) == 1
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

return M

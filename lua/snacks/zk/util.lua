local uv = vim.loop
local zk = require("snacks.zk")

local M = {}
M.picker = {}

---Get zk picker
---@return snacks.Picker?
function M.picker.get_picker()
  return Snacks.picker.get({ source = "zk" })[1]
end

---Get cwd (when ctx.filter.cwd is not available)
---@return string?
function M.picker.get_cwd()
  local picker = M.picker.get_picker()
  if picker then
    return picker.cwd(picker)
  end
end

---Focus
---@param win string? "input"|"list"|"preview"
---@param opts? {show?: boolean}
function M.picker.focus(win, opts)
  local picker = M.picker.get_picker()
  if picker then
    return picker:focus(win, opts)
  end
end

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
function M.sort(opts)
  local sort = opts.sort or require("snacks.zk.sort").default()
  if type(sort) == "table" then
    return require("snacks.zk.sort").default(sort)
  elseif type(sort) == "function" then
    return sort
  end
end

return M

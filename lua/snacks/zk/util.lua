local zk = require("snacks.zk")

local M = {}

---Returns a formatted string used for sorting
---@param entry snacks.picker.explorer.Node|snacks.picker.explorer.Item
function M.get_sort_string(entry)
  local full_path = entry.file or entry.path
  local dirname, basename = full_path:match("(.*)/(.*)")
  dirname = dirname or ""
  basename = basename or full_path
  local hidden = entry.hidden or basename:sub(1, 1) == "."
  local label = entry.zk and entry.zk.title or basename
  local kind = entry.dir and "D" or "F" -- D:directories -> F:files
  local visibility = not hidden and " " or "." -- " ":visible -> .:hidden
  -- local zk_flag = entry.zk and "@" or "_" -- @:has zk -> _:no zk
  local zk_flag = entry.zk and "あ" or " " -- @:has zk -> _:no zk
  local parent_sort = entry.parent and entry.parent.sort or full_path -- DEBUG: Does this work correctly ???
  sort_str = string.format("%s[%s%s%s]%s", parent_sort, kind, visibility, zk_flag, label)
  -- e.g.
  -- parent[F @]has_zk
  -- parent[F _]none_zk
  -- parent[D._].hidden_dir
  return sort_str
end

---Change current sorter
---@param sorter (string|table)
function M.change_sorter(sorter)
  if type(sorter) == "string" then
    sorter = sorter or zk.opts.default_sorter
    local sorter_func = zk.opts.sorters[sorter]
    zk.opts.sort = sorter_func
  -- TODO: Add refresh here? (maybe NO)
  elseif type(sorter) == "function" then
    zk.opts.sort = sorter
  end
end

---Return sort function : copied from `lua/snacks/picker/config/init.lua: M.sort()`
---Use custom default() in `lua/snacks/zk/sort.lua` instead
---@param opts snacks.picker.Config
function M.sort(opts)
  local sort = opts.sort or require("snacks.zk.sort").default()
  sort = type(sort) == "table" and require("snacks.zk.sort").default(sort) or sort
  ---@cast sort snacks.picker.sort
  return sort
end

return M

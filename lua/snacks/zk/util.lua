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
  local zk_flag = entry.zk and "@" or "_" -- @:has zk -> _:no zk
  local parent_sort = entry.parent and entry.parent.sort or full_path -- DEBUG: Does this work correctly ???
  sort_str = string.format("%s[%s%s%s]%s", parent_sort, kind, visibility, zk_flag, label)
  -- e.g.
  -- parent[F @]has_zk
  -- parent[F _]none_zk
  -- parent[D._].hidden_dir
  return sort_str
end

return M

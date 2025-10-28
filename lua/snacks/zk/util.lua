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
  local visibility = not hidden and "+" or "." -- +:visible -> .:hidden
  local zk_flag = entry.zk and not entry.dir and "@" or "_" -- @:has zk -> _:none-zk (directories are always considered as none-zk)
  local parent_sort = entry.parent and entry.parent.sort or full_path
  sort_str = string.format("%s[%s%s%s]%s", parent_sort, kind, visibility, zk_flag, label)
  -- e.g.
  -- dir_name[D+_]visible_dir
  -- dir_name[D._].hidden_dir
  -- dir_name[F+@]file_with_zk
  -- dir_name[F+_]none_zk
  -- dir_name[F._].hidden_file
  return sort_str
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

function M.get_cwd()
  -- zk.notebook_path -- DEBUG: Why nil ?
  local picker = Snacks.picker.get({ source = "zk" })[1]
  return picker.cwd(picker)
end

return M

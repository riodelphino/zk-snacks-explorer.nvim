local zk = require("snacks.zk")

local M = {}

---Returns a hierarchical sort string based purely on file path
---@param entry snacks.picker.explorer.Node|snacks.picker.explorer.Item
function M.get_sort_string(entry)
  local path = entry.file or entry.path
  if not path then
    return ""
  end

  local parts = vim.split(path, "/", { trimempty = true })

  local sort_parts = {}
  for i, name in ipairs(parts) do
    local is_last = (i == #parts)
    local hidden = name:sub(1, 1) == "."
    local kind = (is_last and not entry.dir) and "#" or "!"
    local visibility = not hidden and "+" or "."
    local zk_flag = (is_last and entry.zk and not entry.dir) and "@" or "_"
    table.insert(sort_parts, string.format("[%s%s%s]%s", kind, visibility, zk_flag, name))
  end

  return table.concat(sort_parts)
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

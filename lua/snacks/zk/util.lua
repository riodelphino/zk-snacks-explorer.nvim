local uv = vim.loop
local zk = require("snacks.zk")

local M = {}

---Get a sort key (part)
-- (e.g.
--   [!+_]visible_dir
--   [!._].hidden_dir
--   [#+@]file_with_zk
--   [#+_]file_not_zk
--   [#._].hidden_file
-- directories are always considered as none-zk.
---@param part string
---@param is_last boolean
---@reaturn string
local function get_sort_key_part(part, entry, is_last)
  local hidden = part:sub(1, 1) == "."
  local kind = (is_last and not entry.dir) and "#" or "!" -- !:directories -> #:files
  local visibility = not hidden and "+" or "." -- +:visible -> .:hidden
  local zk_flag = (is_last and entry.zk and not entry.dir) and "@" or "_" -- @:has zk -> _:none-zk
  return string.format("[%s%s%s]%s", kind, visibility, zk_flag, part)
end

---Get a hierarchical sort key based on path
---@param entry snacks.picker.explorer.Node|snacks.picker.explorer.Item
---@return string
function M.get_sort_key(entry)
  local path = entry.file or entry.path -- fallback Node -> Item
  local normalized_path = uv.fs_realpath(path) or path
  local parts = vim.split(normalized_path, "/", { trimempty = true })

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

---Get cwd easily (when ctx.filter.cwd is not available)
---@return string
function M.get_cwd()
  -- zk.notebook_path -- DEBUG: Why nil ?
  local picker = Snacks.picker.get({ source = "zk" })[1]
  return picker.cwd(picker)
end

return M

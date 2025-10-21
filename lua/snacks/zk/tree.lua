---@class snacks.picker.explorer.Tree snacks.picker.explorer.Tree
local Tree = require("snacks.explorer.tree") -- Extend the Tree class with custom functions below.
-- TODO: 直接拡張は危険。
local zk_sorter = require("snacks.zk.sort") ---@type function -- TODO: Should the sorter function be included in opts?

local function assert_dir(path)
  assert(vim.fn.isdirectory(path) == 1, "Not a directory: " .. path)
end

---@param node snacks.picker.explorer.Node
---@param fn fun(node: snacks.picker.explorer.Node):boolean? return `false` to not process children, `true` to abort
---@param opts? {all?: boolean}
function Tree:walk_zk(node, fn, opts)
  local abort = false ---@type boolean?
  abort = fn(node)
  if abort ~= nil then
    return abort
  end
  local children = vim.tbl_values(node.children) ---@type snacks.picker.explorer.Node[]
  table.sort(children, zk_sorter) -- Sort
  for c, child in ipairs(children) do
    child.last = c == #children
    abort = false
    if child.dir and (child.open or (opts and opts.all)) then
      abort = self:walk_zk(child, fn, opts)
    else
      abort = fn(child)
    end
    if abort then
      return true
    end
  end
  return false
end

---@param cwd string
---@param cb fun(node: snacks.picker.explorer.Node)
---@param opts? {expand?: boolean}|snacks.picker.explorer.Filter
function Tree:get_zk(cwd, cb, opts)
  -- opts.hidden|ignored|exclude[]|include[] are automatically considered somehow.
  opts = opts or {}
  assert_dir(cwd)
  local node = self:find(cwd)
  node.open = true
  local filter = self:filter(opts)

  local zk = require("snacks.zk")
  local notes_cache = zk.notes_cache
  local query_enabled = (zk.query.desc ~= "All")
  print("zk.query.desc: " .. zk.query.desc .. " query_enabled:" .. tostring(query_enabled))

  ---@type snacks.picker.Config
  local zk_opts = require("snacks.picker").sources.zk

  self:walk_zk(node, function(n)
    if zk_opts.formatters.file.markdown_only then
      if n ~= node and n.dir == false and not n.path:match("%.md$") then -- Restrict glob to markdown files
        return false
      end
    end
    local zk_note = notes_cache[node.path] or nil

    if n ~= node then
      if not filter(n) then
        return false
      end
    end
    if n.dir and n.open and not n.expanded and opts.expand ~= false then
      self:expand(n)
    end
    cb(n)
  end)
end

-- print(item.file .. " : " .. (zk_note ~= nil and zk_note.title or "nil"))
-- -- DEBUG:
-- if not query_enabled or (query_enabled and zk_note) then
--   cb(item)
-- end

return Tree

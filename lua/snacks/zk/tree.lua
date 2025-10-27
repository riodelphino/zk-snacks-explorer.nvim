-- local config = require("snacks.picker.config")
local zk = require("snacks.zk")
local zk_util = require("snacks.zk.util")

---@type snacks.picker.explorer.Tree
local ExplorerTree = require("snacks.explorer.tree")
---@class snacks.picker.zk.Tree
local Tree = {}

setmetatable(Tree, { __index = ExplorerTree }) -- Inherit from snacks.explorer.Tree class

local function assert_dir(path)
  assert(vim.fn.isdirectory(path) == 1, "Not a directory: " .. path)
end

---@param node snacks.picker.zk.Node
---@param fn fun(node: snacks.picker.zk.Node):boolean? return `false` to not process children, `true` to abort
---@param opts? {all?: boolean}
function Tree:walk(node, fn, opts)
  print("WALK start:", node.path)
  local abort = false ---@type boolean?
  abort = fn(node)
  if abort ~= nil then
    return abort
  end

  -- Ensure each child node has `sort` set before sorting
  ---@param child snacks.picker.zk.Node
  for k, child in pairs(node.children) do
    if not child.sort then -- DEBUG: or should set sort string everytime? (If omit this `if ~ end` the item expantion does not work.)
      local note = zk.notes_cache[child.path]
      child.title = note and note.title or nil
      if note then
        -- node.children[k] = vim.tbl_deep_extend("force", child, note) -- Should rewrite children[k] directory (not child)
        child = vim.tbl_deep_extend("force", child, note) -- Should rewrite children[k] directory (not child)
      end
      -- node.children[k].sort = zk_util.get_sort_string(node.children[k]) -- Should rewrite children[k] directory (not child)
      child.sort = zk_util.get_sort_string(child)
    end
  end

  local children = vim.tbl_values(node.children) ---@type snacks.picker.zk.Node[]
  -- local sorter = config.sort(zk.opts) -- Use built-in sort system
  local sorter = zk_util.sort(zk.opts) -- Use built-in sort system
  -- DEBUG:
  local function print_children(prefix, target_children)
    if node.path ~= "/Users/rio/Projects/terminal/zk-md-tests/notes" then -- notes フォルダのみテスト
      return
    end
    local ret = ""
    for _, child in ipairs(target_children) do
      local child_simple = vim.deepcopy(child)
      child_simple.parent = nil -- Remove parent
      ret = ret .. vim.inspect(child_simple) .. ",\n"
    end
    print(prefix .. ": " .. node.path .. ": children: \n" .. ret) -- DEBUG:
  end

  print_children("before", children)
  table.sort(children, sorter)
  print_children("after", children)

  for c, child in ipairs(children) do
    child.last = c == #children
    abort = false
    if child.dir and (child.open or (opts and opts.all)) then
      abort = self:walk(child, fn, opts)
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
---@param cb fun(node: snacks.picker.zk.Node)
---@param opts? {expand?: boolean}|snacks.picker.explorer.Filter
function Tree:get(cwd, cb, opts)
  -- opts.hidden|ignored|exclude[]|include[] are automatically considered somehow.
  opts = opts or {}
  assert_dir(cwd)

  local node = self:find(cwd) ---@cast node snacks.picker.zk.Node
  node.open = true
  local filter = self:filter(opts)

  local notes_cache = zk.notes_cache
  local query_enabled = (zk.opts.query.desc:lower() ~= zk.opts.default_query.desc:lower())

  self:walk(node, function(n)
    if zk.opts.formatters.file.markdown_only then
      if n ~= node and n.dir == false and not n.path:match("%.md$") then -- Restrict glob to markdown files
        return false
      end
    end

    -- Skip if not listed in notes_cache with query enabled
    local zk_note = notes_cache[n.path] or nil
    if query_enabled and not zk_note then
      return false
    end

    if n ~= node then
      if not filter(n) then
        return false
      end
    end
    if n.dir and n.open and not n.expanded and opts.expand ~= false then
      self:expand(n)
    end
    n.sort = zk_util.get_sort_string(n)
    n.sort_base = zk_util.get_sort_string(n, true)
    cb(n)
  end)
end

return Tree

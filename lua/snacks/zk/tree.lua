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

---Returns true if the path is inside the cwd, or equal to it
---@param cwd string
---@param path string
function Tree:in_cwd(cwd, path)
  cwd = vim.fs.normalize(cwd)
  path = vim.fs.normalize(path)
  return path == cwd or path:find(cwd .. "/", 1, true) == 1
end

---@param node snacks.picker.zk.Node
---@param fn fun(node: snacks.picker.zk.Node):boolean? return `false` to not process children, `true` to abort
---@param opts? {all?: boolean, cwd: string}
function Tree:walk(node, fn, opts)
  local abort = false ---@type boolean?
  abort = fn(node)
  if abort ~= nil then
    return abort
  end

  -- Ensure each child node has `sort` set before sorting
  ---@param child snacks.picker.zk.Node
  for _, child in pairs(node.children) do
    if not child.sort then -- DEBUG: or should set sort string everytime? (If omit this `if ~ end` the item expantion does not work.)
      local zk_note = zk.notes_cache[child.path]
      child.zk = zk_note or nil -- Add zk note data to the `Node`
      child.sort = zk_util.sort.get_sort_key(child, opts.cwd)
    end
  end

  local children = vim.tbl_values(node.children) ---@type snacks.picker.zk.Node[]
  local sorter = zk_util.sort.get_sorter(zk.opts) -- Use built-in sort system

  table.sort(children, sorter)

  -- if node.path == "/Users/rio/Projects/terminal/zk-md-tests" then -- DEBUG: REMOVE THIS
  --   print("children: " .. vim.inspect(children))
  -- end

  for c, child in ipairs(children) do
    if c == #children then
      child.last = true
    else
      child.last = false
    end
    -- FIXME: A problem where the hidden dot file becomes last and the currently displayed final file does not become last.
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

    local zk_note = notes_cache[n.path] or nil

    -- Skip all nodes unlisted in notes_cache when `include_none_zk` is false or nil
    if not zk.opts.query.include_none_zk and not zk_note then
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
    n.sort = zk_util.sort.get_sort_key(n, cwd)

    cb(n)
  end, { cwd = cwd })
end

return Tree

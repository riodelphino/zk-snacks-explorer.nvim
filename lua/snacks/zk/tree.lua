---@type snacks.picker.explorer.Tree
local ExplorerTree = require("snacks.explorer.tree")
---@class snacks.picker.zk.Tree : snacks.picker.explorer.Tree
local Tree = {}

setmetatable(Tree, { __index = ExplorerTree }) -- Inherit from snacks.explorer.Tree class

local zk = require("snacks.zk")

local function assert_dir(path)
  assert(vim.fn.isdirectory(path) == 1, "Not a directory: " .. path)
end

---@param node snacks.picker.explorer.Node
---@param fn fun(node: snacks.picker.explorer.Node):boolean? return `false` to not process children, `true` to abort
---@param opts? {all?: boolean}
function Tree:walk(node, fn, opts)
  local abort = false ---@type boolean?
  abort = fn(node)
  if abort ~= nil then
    return abort
  end
  local children = vim.tbl_values(node.children) ---@type snacks.picker.explorer.Node[]
  -- table.sort(children, function(a, b) -- DEBUG: Can use default sort system instead?
  --   return zk.sorter(a, b)
  -- end)
  -- ここでは item じゃなく node なので、picker の sort システムは使えない？
  -- 無理やり sort システムを呼び出して sort することは可能か？ -> 難しそうだ node だし

  -- TODO: Use built-in sort system:
  local sort_function = require("snacks.picker.config").sort(zk.opts)
  table.sort(children, sort_function) -- sort children

  -- DEBUG: TEST CODE
  --
  -- table.sort(children, sort_function)
  -- local tbl = { { file = "c", sort = "c" }, { file = "b", sort = "b" }, { file = "a", sort = "a" } }
  -- print(type(sort_function))
  -- -- print("children: " .. vim.inspect(children))
  --
  -- tbl = {
  --   {
  --     children = {},
  --     dir = true,
  --     hidden = false,
  --     name = "c",
  --     parent = nil,
  --     path = "/Users/rio/Projects/terminal/zk-md-tests/c",
  --     type = "directory",
  --     sort = "c",
  --   },
  --   {
  --     children = {},
  --     dir = true,
  --     hidden = false,
  --     name = "b",
  --     parent = nil,
  --     path = "/Users/rio/Projects/terminal/zk-md-tests/b",
  --     type = "directory",
  --     sort = "b",
  --   },
  --   {
  --     children = {},
  --     dir = true,
  --     hidden = false,
  --     name = "a",
  --     parent = nil,
  --     path = "/Users/rio/Projects/terminal/zk-md-tests/a",
  --     type = "directory",
  --     sort = "a",
  --   },
  -- }
  -- -- nil
  -- -- print(vim.inspect(table.sort(tbl, function(a, b)
  -- --   return sort_function(a, b)
  -- -- end)))
  -- -- sort_function = zk.opts.sort -- これも sort 結果が nil になる
  -- sort_function = function(a, b)
  --   print("sort: a: " .. vim.inspect(a))
  --   return a.sort < b.sort
  -- end
  -- table.sort(tbl, sort_function)
  -- print("tbl sorted by sort_function: " .. vim.inspect(tbl))

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
---@param cb fun(node: snacks.picker.explorer.Node)
---@param opts? {expand?: boolean}|snacks.picker.explorer.Filter
function Tree:get(cwd, cb, opts)
  -- opts.hidden|ignored|exclude[]|include[] are automatically considered somehow.
  opts = opts or {}
  assert_dir(cwd)
  local node = self:find(cwd)
  node.open = true
  local filter = self:filter(opts)

  local notes_cache = zk.notes_cache
  local query_enabled = (zk.query.desc ~= zk.opts.queries[zk.opts.default_query].desc)

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
    cb(n)
  end)
end

return Tree

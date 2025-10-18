local Tree = require("snacks.explorer.tree")
local zk_sorter = require("snacks.zk.sort") -- TODO: sort should be included in opts??

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

function Tree:get_zk(cwd, cb, opts)
  opts = opts or {}
  assert_dir(cwd)
  local node = self:find(cwd)
  node.open = true
  local filter = self:filter(opts)

  self:walk_zk(node, function(n)
    -- NOTE: Automatically consider opts.hidden|ignored|exclude[]|include[] somehow.

    local zk_opts = require("snacks.picker").sources.zk
    if zk_opts.formatters.file.markdown_only then
      if n ~= node and n.dir == false and not n.path:match("%.md$") then
        return false
      end
    end

    -- table.insert(nodes, n) -- DEBUG: node が nil になるのでいったん消した

    -- NOTE: Copeid from explorer `Tree:get()`
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

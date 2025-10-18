local Tree = require("snacks.explorer.tree")
local zk = require("snacks.zk")

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
  table.sort(children, function(a, b)
    if a.dir ~= b.dir then
      return a.dir
    end
    print("zk_walk is called")
    return a.name < b.name
  end)
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
  opts.expand = true -- DEBUG: いったん全部のフォルダを取得？できず
  assert_dir(cwd)
  local node = self:find(cwd)
  node.open = true
  local filter = self:filter(opts)

  local nodes = {}

  -- self:walk_zk(node, function(n)
  --    if n ~= node and n.dir == false and not n.path:match("%.md$") then -- DEBUG: この if いったん有効に
  --       return false
  --    end
  --    table.insert(nodes, n)
  -- end)

  self:walk(node, function(n)
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
  -- DEBUG: ここで sort するのは、ベースとなった Tree:get() の構造に反している。
  -- そもそもの Tree:walk_zk() が返すリストが、すでに sort された状態であるべきだ。
  --
  -- A. まず全ファイルを列挙 -> そのアイテムリストに対して、＜dir/file、dotfileか否か、title 有り無し、一般ファイル＞ でソートしておく？？？
  -- B. いや、walk はそのディレクトリ内の１階層ずつを処理するので、全部じゃなくてその都度そのフォルダ内の同階層のあみをソートすれば済む。
  cb(n)
end

return Tree

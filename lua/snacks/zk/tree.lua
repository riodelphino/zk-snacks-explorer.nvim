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

   self:walk_zk(node, function(n)
      if n ~= node and n.dir == false and not n.path:match("%.md$") then -- DEBUG: この if いったん有効に
         return false
      end
      table.insert(nodes, n)
   end)

   table.sort(nodes, function(a, b)
      -- 0. ルート優先
      if a.dir and a.path == cwd then
         return true
      end
      if b.dir and b.path == cwd then
         return false
      end

      -- 1. ディレクトリ優先
      if a.dir and not b.dir then
         return true
      end
      if b.dir and not a.dir then
         return false
      end

      local ta = (zk.notes_cache[a.path] and zk.notes_cache[a.path].title)
      local tb = (zk.notes_cache[b.path] and zk.notes_cache[b.path].title)

      local na = vim.fs.basename(a.path)
      local nb = vim.fs.basename(b.path)

      -- 2. タイトルの有無で優先
      if ta and not tb then
         return true
      end
      if tb and not ta then
         return false
      end

      -- 3. ドットファイルは後方
      local a_dot = na:match("^%.") or false
      local b_dot = nb:match("^%.") or false
      if a_dot and not b_dot then
         return false
      end
      if b_dot and not a_dot then
         return true
      end

      -- 4. タイトルがあればタイトルで比較、なければファイル名で比較
      local sa = ta or na
      local sb = tb or nb
      return sa:lower() < sb:lower()
   end)

   for idx, n in ipairs(nodes) do
      cb({
         file = n.path,
         dir = n.dir,
         title = (zk.notes_cache[n.path] and zk.notes_cache[n.path].title) or vim.fs.basename(n.path),
         idx = idx,
         type = n.type,
      })
   end
   -- end)
end

return Tree

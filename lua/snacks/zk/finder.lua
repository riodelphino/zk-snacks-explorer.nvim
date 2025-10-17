local explorer = require("snacks.picker.source.explorer")
local Tree = require("snacks.explorer.tree")
local zk = require("snacks.zk")

local function assert_dir(path)
   assert(vim.fn.isdirectory(path) == 1, "Not a directory: " .. path)
end

function Tree:get_zk(cwd, cb, opts)
   opts = opts or {}
   assert_dir(cwd)
   local node = self:find(cwd)
   node.open = true

   local nodes = {}

   self:walk(node, function(n)
      if n ~= node and n.dir == false and not n.path:match("%.md$") then
         return false
      end
      table.insert(nodes, n)
   end)

   vim.schedule(function()
      table.sort(nodes, function(a, b)
         local ta = (require("snacks.zk").notes_cache[a.path] and require("snacks.zk").notes_cache[a.path].title)
            or vim.fs.basename(a.path)
         local tb = (require("snacks.zk").notes_cache[b.path] and require("snacks.zk").notes_cache[b.path].title)
            or vim.fs.basename(b.path)
         return ta:lower() < tb:lower()
      end)

      for idx, n in ipairs(nodes) do
         cb({
            file = n.path,
            dir = n.dir,
            title = (require("snacks.zk").notes_cache[n.path] and require("snacks.zk").notes_cache[n.path].title)
               or vim.fs.basename(n.path),
            idx = idx,
            type = n.type,
         })
      end
   end)
end

-- ---@param opts snacks.picker.explorer.Config
-- ---@type snacks.picker.finder
-- local finder = function(opts, ctx)
--    local notes_cache = require("snacks.zk").notes_cache
--    local explorer = require("snacks.picker.source.explorer")
--    local base_finder = explorer.explorer(opts, ctx)
--
--    return function(cb)
--       base_finder(function(item)
--          if item.type == "file" then
--             if item.file and item.file:match("%.md$") then
--                local note = notes_cache[item.file]
--                if note and note.title and note.title ~= "" then
--                   -- vim.fs.joinpath(vim.fn.fnamemodify(item.file, ":p:h"), note.title)
--                   item.title = note.title
--                end
--             end
--          end
--          if not item.title then -- titleでソートするには全アイテムが title を保持しないといけないかも、の対策
--             item.title = item.file
--          end
--          cb(item)
--       end)
--    end
-- end

-- ---@param opts snacks.picker.explorer.Config
-- ---@type snacks.picker.finder
-- finder = function(opts, ctx)
--    local state = explorer.get_state(ctx.picker)
--
--    if state:setup(ctx) then
--       return explorer.search(opts, ctx)
--    end
--
--    if opts.git_status then
--       require("snacks.explorer.git").update(ctx.filter.cwd, {
--          untracked = opts.git_untracked,
--          on_update = function()
--             if ctx.picker.closed then
--                return
--             end
--             ctx.picker.list:set_target()
--             ctx.picker:find()
--          end,
--       })
--    end
--
--    if opts.diagnostics then
--       require("snacks.explorer.diagnostics").update(ctx.filter.cwd)
--    end
--
--    return function(cb)
--       if state.on_find then
--          ctx.picker.matcher.task:on("done", vim.schedule_wrap(state.on_find))
--          state.on_find = nil
--       end
--       local items = {} ---@type table<string, snacks.picker.explorer.Item>
--       local top = Tree:find(ctx.filter.cwd)
--       local last = {} ---@type table<snacks.picker.explorer.Node, snacks.picker.explorer.Item>
--       Tree:get(ctx.filter.cwd, function(node)
--          local parent = node.parent and items[node.parent.path] or nil
--          local status = node.status
--          if not status and parent and parent.dir_status then
--             status = parent.dir_status
--          end
--          local item = {
--             file = node.path,
--             dir = node.dir,
--             open = node.open,
--             dir_status = node.dir_status or parent and parent.dir_status,
--             text = node.path,
--             parent = parent,
--             hidden = node.hidden,
--             ignored = node.ignored,
--             status = (not node.dir or not node.open or opts.git_status_open) and status or nil,
--             last = true,
--             type = node.type,
--             severity = (not node.dir or not node.open or opts.diagnostics_open) and node.severity or nil,
--          }
--          -- zk
--          local zk_note = zk.notes_cache[item.file]
--          item.title = zk_note and zk_note.title
--
--          if last[node.parent] then
--             last[node.parent].last = false
--          end
--          last[node.parent] = item
--          if top == node then
--             item.hidden = false
--             item.ignored = false
--          end
--          items[node.path] = item
--          cb(item) -- DEBUG: ここは無しにして下でソートする
--       end, { hidden = opts.hidden, ignored = opts.ignored, exclude = opts.exclude, include = opts.include })
--       -- vim.schedule(function() -- DEBUG: ソートされない
--       --    table.sort(items, function(a, b)
--       --       return (a.title or ""):lower() < (b.title or ""):lower()
--       --    end)
--       --    for _, item in ipairs(items) do
--       --       cb(item)
--       --    end
--       --    print("items: " .. vim.inspect(items))
--       -- end)
--       vim.schedule(function()
--          local sorted_paths = {}
--          for path in pairs(items) do
--             table.insert(sorted_paths, path)
--          end
--
--          table.sort(sorted_paths, function(a, b)
--             local ta = items[a].title or vim.fs.basename(a)
--             local tb = items[b].title or vim.fs.basename(b)
--             return ta:lower() < tb:lower()
--          end)
--
--          for i, path in ipairs(sorted_paths) do
--             items[path].idx = i
--             cb(items[path])
--          end
--       end)
--
--       -- DEBUG: 上記 return の関数の外で行うソートは意味なし
--       -- table.sort(items, function(a, b)
--       --    return (a.title or ""):lower() < (b.title or ""):lower()
--       -- end)
--       -- for _, item in ipairs(items) do
--       --    cb(item)
--       -- end
--    end
-- end

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
local finder = function(opts, ctx)
   local state = explorer.get_state(ctx.picker)

   if state:setup(ctx) then
      return explorer.search(opts, ctx)
   end

   if opts.git_status then
      require("snacks.explorer.git").update(ctx.filter.cwd, {
         untracked = opts.git_untracked,
         on_update = function()
            if ctx.picker.closed then
               return
            end
            ctx.picker.list:set_target()
            ctx.picker:find()
         end,
      })
   end

   if opts.diagnostics then
      require("snacks.explorer.diagnostics").update(ctx.filter.cwd)
   end

   return function(cb)
      local nodes = {} ---@type snacks.picker.explorer.Node[]
      local top = Tree:find(ctx.filter.cwd)

      -- 全ノードを一旦 nodes に集める
      Tree:get_zk(ctx.filter.cwd, function(n)
         table.insert(nodes, n)
      end, {
         hidden = opts.hidden,
         ignored = opts.ignored,
         exclude = opts.exclude,
         include = opts.include,
      })

      -- 非同期なのでスケジュールしてソート後に cb() に渡す
      vim.schedule(function()
         -- タイトルでソート
         table.sort(nodes, function(a, b)
            local ta = (zk.notes_cache[a.path] and zk.notes_cache[a.path].title) or vim.fs.basename(a.path)
            local tb = (zk.notes_cache[b.path] and zk.notes_cache[b.path].title) or vim.fs.basename(b.path)
            return ta:lower() < tb:lower()
         end)

         -- idx を順番に書き換えて cb() に渡す
         for idx, n in ipairs(nodes) do
            local parent = n.parent
            local status = n.status or (parent and parent.dir_status)
            local item = {
               file = n.path,
               dir = n.dir,
               open = n.open,
               dir_status = n.dir_status or (parent and parent.dir_status),
               text = n.path,
               parent = parent,
               hidden = n.hidden,
               ignored = n.ignored,
               status = (not n.dir or not n.open or opts.git_status_open) and status or nil,
               last = true,
               type = n.type,
               severity = (not n.dir or not n.open or opts.diagnostics_open) and n.severity or nil,
               title = (zk.notes_cache[n.path] and zk.notes_cache[n.path].title) or vim.fs.basename(n.path),
               idx = idx, -- idx をソート順に更新
            }
            cb(item)
         end
      end)
   end
end

return finder

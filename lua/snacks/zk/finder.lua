local explorer = require("snacks.picker.source.explorer")
local Tree = require("snacks.explorer.tree")

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

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
finder = function(opts, ctx)
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
      if state.on_find then
         ctx.picker.matcher.task:on("done", vim.schedule_wrap(state.on_find))
         state.on_find = nil
      end
      local items = {} ---@type table<string, snacks.picker.explorer.Item>
      local top = Tree:find(ctx.filter.cwd)
      local last = {} ---@type table<snacks.picker.explorer.Node, snacks.picker.explorer.Item>
      Tree:get(ctx.filter.cwd, function(node)
         local parent = node.parent and items[node.parent.path] or nil
         local status = node.status
         if not status and parent and parent.dir_status then
            status = parent.dir_status
         end
         local item = {
            file = node.path,
            dir = node.dir,
            open = node.open,
            dir_status = node.dir_status or parent and parent.dir_status,
            text = node.path,
            parent = parent,
            hidden = node.hidden,
            ignored = node.ignored,
            status = (not node.dir or not node.open or opts.git_status_open) and status or nil,
            last = true,
            type = node.type,
            severity = (not node.dir or not node.open or opts.diagnostics_open) and node.severity or nil,
         }
         if last[node.parent] then
            last[node.parent].last = false
         end
         last[node.parent] = item
         if top == node then
            item.hidden = false
            item.ignored = false
         end
         items[node.path] = item
         cb(item)
      end, { hidden = opts.hidden, ignored = opts.ignored, exclude = opts.exclude, include = opts.include })
   end
end

return finder

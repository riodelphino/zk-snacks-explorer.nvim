local Tree = require("snacks.explorer.tree")

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
local function search(opts, ctx)
   opts = Snacks.picker.util.shallow_copy(opts)
   opts.cmd = "fd"
   opts.cwd = ctx.filter.cwd
   opts.notify = false
   opts.args = {
      "--type",
      "d", -- include directories
      "--path-separator", -- same everywhere
      "/",
   }
   opts.dirs = { ctx.filter.cwd }
   ctx.picker.list:set_target()

   ---@type snacks.picker.explorer.Item
   local root = {
      file = opts.cwd,
      dir = true,
      open = true,
      text = "",
      sort = "",
      internal = true,
   }

   local files = require("snacks.picker.source.files").files(opts, ctx)

   local dirs = {} ---@type table<string, snacks.picker.explorer.Item>
   local last = {} ---@type table<snacks.picker.finder.Item, snacks.picker.finder.Item>

   ---@async
   return function(cb)
      cb(root)

      ---@param item snacks.picker.explorer.Item
      local function add(item)
         local dirname, basename = item.file:match("(.*)/(.*)")
         dirname, basename = dirname or "", basename or item.file
         local parent = dirs[dirname] ~= item and dirs[dirname] or root
         basename = item.title and ("#" .. item.title) or basename
         -- ! -> # -> %

         -- hierarchical sorting
         if item.dir then
            item.sort = parent.sort .. "!" .. basename .. " "
         else
            item.sort = parent.sort .. "%" .. basename .. " "
         end
         item.hidden = basename:sub(1, 1) == "."
         item.text = item.text:sub(1, #opts.cwd) == opts.cwd and item.text:sub(#opts.cwd + 2) or item.text
         local node = Tree:node(item.file)
         if node then
            item.dir = node.dir
            item.type = node.type
            item.status = (not node.dir or opts.git_status_open) and node.status or nil
         end

         if opts.tree then
            -- tree
            item.parent = parent
            if not last[parent] or last[parent].sort < item.sort then
               if last[parent] then
                  last[parent].last = false
               end
               item.last = true
               last[parent] = item
            end
         end
         -- add to picker
         cb(item)
      end

      -- get files and directories
      files(function(item)
         ---@cast item snacks.picker.explorer.Item
         item.cwd = nil -- we use absolute paths

         -- Directories
         if item.file:sub(-1) == "/" then
            item.dir = true
            item.file = item.file:sub(1, -2)
            if dirs[item.file] then
               dirs[item.file].internal = false
               return
            end
            item.open = true
            dirs[item.file] = item
         end

         -- Add parents when needed
         for dir in Snacks.picker.util.parents(item.file, opts.cwd) do
            if dirs[dir] then
               break
            else
               dirs[dir] = {
                  text = dir,
                  file = dir,
                  dir = true,
                  open = true,
                  internal = true,
               }
               add(dirs[dir])
            end
         end

         add(item)
      end)
   end
end

return search

local Tree = require("snacks.explorer.tree")
local M = {}

-- ---@param opts snacks.picker.explorer.Config
-- ---@type snacks.picker.finder
-- function M.zk_finder(opts, ctx)
--    local notes_cache = require("snacks.zk").notes_cache
--    local explorer = require("snacks.picker.source.explorer")
--
--    -- 元の finder を取得（explorer または search）
--    local base_finder = explorer.explorer(opts, ctx)
--
--    return function(cb)
--       base_finder(function(item)
--          -- item.sort を書き換える
--          if item.file then
--             local basename = vim.fs.basename(item.file)
--
--             -- Markdown ファイルの場合、title を使う
--             if item.file:match("%.md$") then
--                local note = notes_cache[item.file]
--                if note and note.title and note.title ~= "" then
--                   basename = note.title
--                end
--             end
--
--             -- 親のソートキーを取得
--             local parent_sort = ""
--             if item.parent and item.parent.sort then
--                parent_sort = item.parent.sort
--             elseif item.sort then
--                -- 既存の sort から親部分を抽出
--                parent_sort = item.sort:match("^(.*)([!#])") or ""
--             end
--
--             -- 新しいソートキーを生成
--             if item.dir then
--                item.sort = parent_sort .. "!" .. basename:lower() .. " "
--             else
--                item.sort = parent_sort .. "#" .. basename:lower() .. " "
--             end
--          end
--
--          cb(item)
--       end)
--    end
-- end

-- ---@param opts snacks.picker.explorer.Config
-- ---@type snacks.picker.finder
-- function M.zk_finder(opts, ctx)
--    local notes_cache = require("snacks.zk").notes_cache
--    local state = require("snacks.picker.source.explorer").get_state(ctx.picker)
--
--    if state:setup(ctx) then
--       return M.search(opts, ctx)
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
--          if last[node.parent] then
--             last[node.parent].last = false
--          end
--          last[node.parent] = item
--          if top == node then
--             item.hidden = false
--             item.ignored = false
--          end
--          item.title = notes_cache[node.path] and notes_cache[node.path].title
--          item.sort = item.title or ""
--          items[node.path] = item
--          cb(item)
--       end, { hidden = opts.hidden, ignored = opts.ignored, exclude = opts.exclude, include = opts.include })
--    end
-- end

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
function M.zk_finder(opts, ctx)
   local notes_cache = require("snacks.zk").notes_cache
   local explorer = require("snacks.picker.source.explorer")
   local base_finder = explorer.explorer(opts, ctx)

   return function(cb)
      base_finder(function(item)
         -- item.sort を書き換える
         if item.type == "directory" then
            item.sort = item.file
         elseif item.type == "file" then
            if item.file and item.file:match("%.md$") then
               local note = notes_cache[item.file]
               if note and note.title and note.title ~= "" then
                  -- sort の最後の部分（basename）を title に置き換え
                  -- 例: "!parent#basename " → "!parent#title "
                  -- local prefix = item.sort:match("^(.+[!#])")
                  -- if prefix then
                  --    item.sort = prefix .. note.title:lower() .. " "
                  -- end
                  item.sort = vim.fs.joinpath(vim.fn.fnamemodify(item.file, ":p:h"), note.title)
               else
                  item.sort = item.file
               end
            else
               item.sort = item.file
            end
         end
         print(vim.inspect(item))

         cb(item)
      end)
   end
end

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
function M.search(opts, ctx)
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

-- ---@param opts snacks.picker.explorer.Config
-- ---@type snacks.picker.finder
-- function M.zk_finder(opts, ctx)
--    -- local notes_cache = require("snacks.zk").notes_cache
--    -- local explorer = require("snacks.picker.source.explorer")
--    -- local base_finder = explorer.explorer(opts, ctx)
--    --
--    -- return function(cb)
--    --    local wrapped_cb = function(item)
--    --       -- 親のソートキー
--    --       local parent_sort = item.parent and item.parent.sort or ""
--    --
--    --       -- basename を取得（title があれば title を使う）
--    --       local basename = vim.fs.basename(item.file)
--    --       if item.file:match("%.md$") then
--    --          local note = notes_cache[item.file]
--    --          print(vim.inspect(note))
--    --          if note and note.title and note.title ~= "" then
--    --             basename = note.title
--    --          end
--    --       end
--    --
--    --       -- 階層的ソートキーを生成
--    --       if item.dir then
--    --          item.sort = parent_sort .. "!" .. basename:lower() .. " "
--    --       else
--    --          item.sort = parent_sort .. "#" .. basename:lower() .. " "
--    --       end
--    --
--    --       cb(item)
--    --    end
--    --
--    --    base_finder(wrapped_cb)
--    -- end
--
--    local state = M.get_state(ctx.picker)
--
--    if state:setup(ctx) then
--       return M.search(opts, ctx)
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
--          if last[node.parent] then
--             last[node.parent].last = false
--          end
--          last[node.parent] = item
--          if top == node then
--             item.hidden = false
--             item.ignored = false
--          end
--          items[node.path] = item
--          cb(item)
--       end, { hidden = opts.hidden, ignored = opts.ignored, exclude = opts.exclude, include = opts.include })
--    end
-- end

-- local explorer = require("snacks.picker.source.explorer")
--
-- ---@param opts snacks.picker.explorer.Config
-- ---@type snacks.picker.finder
-- Snacks.picker.sources.explorer["zk_finder"] = function(opts, ctx)
--    print("find")
--    local notes_cache = require("snacks.zk").notes_cache
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
--          if last[node.parent] then
--             last[node.parent].last = false
--          end
--          last[node.parent] = item
--          if top == node then
--             item.hidden = false
--             item.ignored = false
--          end
--          items[node.path] = item
--          cb(item)
--       end, { hidden = opts.hidden, ignored = opts.ignored, exclude = opts.exclude, include = opts.include })
--    end
-- return function(cb)
--  return function(cb)
--    base_finder(function(item)
--       -- Markdown ファイルの場合、title をソートキーに設定
--       if item.file and item.file:match("%.md$") then
--          local note = notes_cache[item.file]
--          if note and note.title then
--             -- title の小文字版をソートキーに
--             item.sort = note.title:lower()
--          else
--             -- title がない場合はファイル名
--             item.sort = vim.fs.basename(item.file):lower()
--          end
--       elseif item.dir then
--          -- ディレクトリは先頭に来るように
--          item.sort = "!" .. vim.fs.basename(item.file):lower()
--       else
--          -- その他のファイル
--          item.sort = vim.fs.basename(item.file):lower()
--       end
--
--       cb(item)
--    end)
-- end
--
-- end

---@class snacks.picker.explorer.Config: snacks.picker.files.Config|{}
---@field follow_file? boolean follow the file from the current buffer
---@field tree? boolean show the file tree (default: true)
---@field git_status? boolean show git status (default: true)
---@field git_status_open? boolean show recursive git status for open directories
---@field git_untracked? boolean needed to show untracked git status
---@field diagnostics? boolean show diagnostics
---@field diagnostics_open? boolean show recursive diagnostics for open directories
---@field watch? boolean watch for file changes
---@field exclude? string[] exclude glob patterns
---@field include? string[] include glob patterns. These take precedence over `exclude`, `ignored` and `hidden`
local source = {
   -- finder =
   -- finder = "explorer", -- "zk", -- "explorer" is enough
   finder = M.zk_finder, -- DEBUG: 動く？
   -- finder = "zk_finder", -- DEBUG: 動く？
   -- finder = function(opts, ctx)
   --    return Snacks.picker.sources.explorer.zk_finder(opts, ctx)
   -- end,
   reveal = true,
   sort = { fields = { "sort" } }, -- item.sort の文字列でソートする、の意
   supports_live = true,
   tree = false,
   watch = true,
   diagnostics = true,
   diagnostics_open = false,
   git_status = true,
   git_status_open = false,
   git_untracked = true,
   follow_file = true,
   focus = "list",
   auto_close = false,
   jump = { close = false },
   layout = { preset = "sidebar", preview = false },
   formatters = {
      zk_file = { filename_only = true }, -- DEBUG: file に戻さなくて大丈夫？
      severity = { pos = "right" },
   },
   format = function(item, picker)
      return require("snacks.picker.format").zk_file(item, picker)
   end,
   matcher = { sort_empty = false, fuzzy = false },
   config = function(opts)
      -- return require("snacks.picker.source.zk").setup(opts) -- DEBUG: explorer is enough
      return require("snacks.picker.source.explorer").setup(opts)
   end,
   win = {
      list = {
         keys = {
            ["<BS>"] = "explorer_up",
            ["l"] = "confirm",
            ["h"] = "explorer_close", -- close directory
            ["a"] = "explorer_add",
            ["d"] = "explorer_del",
            ["r"] = "explorer_rename",
            ["c"] = "explorer_copy",
            ["m"] = "explorer_move",
            ["o"] = "explorer_open", -- open with system application
            ["P"] = "toggle_preview",
            ["y"] = { "explorer_yank", mode = { "n", "x" } },
            ["p"] = "explorer_paste",
            ["u"] = "explorer_update",
            ["<c-c>"] = "tcd",
            ["<leader>/"] = "picker_grep",
            ["<c-t>"] = "terminal",
            ["."] = "explorer_focus",
            ["I"] = "toggle_ignored",
            ["H"] = "toggle_hidden",
            ["Z"] = "explorer_close_all",
            ["]g"] = "explorer_git_next",
            ["[g"] = "explorer_git_prev",
            ["]d"] = "explorer_diagnostic_next",
            ["[d"] = "explorer_diagnostic_prev",
            ["]w"] = "explorer_warn_next",
            ["[w"] = "explorer_warn_prev",
            ["]e"] = "explorer_error_next",
            ["[e"] = "explorer_error_prev",
         },
      },
   },
}

return source

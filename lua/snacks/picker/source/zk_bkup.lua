---@param opts snacks.picker.zk.Config
---@type snacks.picker.finder
function M.zk(opts, ctx)
  local notes_cache = zk.notes_cache

  local state = M.get_state(ctx.picker)

  if state:setup(ctx) then
    return M.search(opts, ctx)
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

    -- get で各 node を取得 (各 node 取得時の処理は cb が行う。node を nodes ? に追加するなど) -- DEBUG: Translate to English
    Tree:get(
      ctx.filter.cwd,
      function(node)
        local parent = node.parent and items[node.parent.path] or nil
        local status = node.status
        if not status and parent and parent.dir_status then
          status = parent.dir_status
        end

        local zk_note = notes_cache[node.path] or nil
        local title = zk_note and zk_note.title

        ---@type snacks.picker.explorer.Item
        local item = {
          file = node.path,
          dir = node.dir,
          open = node.open,
          dir_status = node.dir_status or (parent and parent.dir_status),
          text = title or node.path,
          parent = parent,
          hidden = node.hidden,
          ignored = node.ignored,
          status = (not node.dir or not node.open or opts.git_status_open) and status or nil,
          last = true,
          type = node.type,
          severity = (not node.dir or not node.open or opts.diagnostics_open) and node.severity or nil,
          title = title,
        }
        if last[node.parent] then
          last[node.parent].last = false
        end
        last[node.parent] = item
        if top == node then
          item.hidden = false
          item.ignored = false
        end

        local dirname, basename = item.file:match("(.*)/(.*)")
        dirname, basename = dirname or "", basename or item.file
        -- local parent = dirs[dirname] ~= item and dirs[dirname] or root

        -- item.text = item.text:sub(1, #opts.cwd) == opts.cwd and item.text:sub(#opts.cwd + 2) or item.text
        -- if node then
        --   item.dir = node.dir
        --   item.type = node.type
        --   item.status = (not node.dir or opts.git_status_open) and node.status or nil
        -- end

        -- Set title as search text
        if item.title then
          item.text = item.title:lower()
        else
          item.text = basename
        end

        -- hierarchical sorting -- DEBUG: Split as a function?
        item.hidden = basename:sub(1, 1) == "."
        local label = item.title or basename
        local kind = item.dir and "D" or "F" -- Sort: D:directories -> F:files
        local priority = item.title and "0" or (item.hidden and "2" or "1") -- Sort: 0:has title -> 1:no title (basename) -> 2:hidden files
        -- item.sort = string.format("%s[%s%s]%s ", parent.sort or parent.file, kind, priority, label) -- e.g. parent[F0]title, parent[F1]basename, parent[D1].hidden_dir
        item.sort = string.format("%s[%s%s]%s ", dirname, kind, priority, label) -- e.g. parent[F0]title, parent[F1]basename, parent[D1].hidden_dir

        cb(item)
        items[node.path] = item
      end,
      { hidden = opts.hidden, ignored = opts.ignored, exclude = opts.exclude, include = opts.include, expand = true }
    )
  end
end

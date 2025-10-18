local Tree = require("snacks.zk.tree") ---@type snacks.picker.explorer.Tree
local explorer = require("snacks.picker.source.explorer")
local zk = require("snacks.zk")

---@param opts snacks.picker.explorer.Config
---@type snacks.picker.finder
local finder = function(opts, ctx)
  local state = explorer.get_state(ctx.picker) -- TODO: explorer の state 取得で良いのか？ zk の get_state じゃなくて？

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

    -- get_zk で各 node を取得 (各 node 取得時の処理は cb が行う。node を nodes ? に追加するなど)
    Tree:get_zk(
      ctx.filter.cwd,
      function(node)
        local parent = node.parent and items[node.parent.path] or nil
        local status = node.status
        if not status and parent and parent.dir_status then
          status = parent.dir_status
        end

        local zk_note = zk.notes_cache and zk.notes_cache[node.path] or nil
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

        -- 親の last 更新
        if last[node.parent] then
          last[node.parent].last = false
        end
        last[node.parent] = item

        -- ルートノードは非 hidden に
        if top == node then
          item.hidden = false
          item.ignored = false
        end

        items[node.path] = item
        cb(item) -- explorer に流す
      end,
      { hidden = opts.hidden, ignored = opts.ignored, exclude = opts.exclude, include = opts.include, expand = true }
    )
  end
end

return finder

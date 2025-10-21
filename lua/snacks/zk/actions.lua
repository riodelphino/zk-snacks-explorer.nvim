local Tree = require("snacks.zk.tree")
local zk = require("snacks.zk")

local uv = vim.uv or vim.loop

local M = require("snacks.explorer.actions") -- TODO: Need to create and get new table?

local function format_item(item)
  return item.desc
end

---Change the query dynamically
M.actions.zk_change_query = function() -- param: tree
  -- local tree = state.tree
  -- local node = tree:get_node()
  -- local id = node:get_id()
  local id
  local picker = Snacks.picker.get({ source = "zk" })[1]
  if picker and not picker.closed then
    local item = picker:current()
    print(vim.inspect(item))
    id = item.file
  end

  local items = {}
  for _, item in pairs(require("snacks.zk.queries")) do
    table.insert(items, item)
  end
  vim.ui.select(items, { prompt = "zk query", format_item = format_item }, function(item)
    if not item then
      return
    end
    -- item.input(state.zk.notebookPath, id, function(res)
    item.input(zk.notebook_path, id, function(res)
      require("snacks.zk").query = res
      print("need refresh")
      -- refresh() -- TODO: Refresh snacks tree ! query must be merged into zk opts.
    end)
  end)
end

return M

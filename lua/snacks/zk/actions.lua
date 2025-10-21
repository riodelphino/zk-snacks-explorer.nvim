local Tree = require("snacks.zk.tree")
local zk = require("snacks.zk")

local uv = vim.uv or vim.loop

local M = require("snacks.explorer.actions") -- Merged with explorer's action.  TODO: Need to create and get new table?

local function format_item(item)
  return item.desc
end

---Change the query dynamically
M.actions.zk_change_query = function()
  local id
  local picker = Snacks.picker.get({ source = "zk" })[1]
  if picker and not picker.closed then
    local item = picker:current()
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
    item.input(zk.notebook_path, id, function(res)
      require("snacks.zk").query = res
      print("need refresh")
      -- refresh() -- TODO: Refresh snacks tree ! `snacks.zk.query` must be merged into zk opts.
    end)
  end)
end

return M

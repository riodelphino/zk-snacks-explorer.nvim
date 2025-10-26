local explorer_actions = require("snacks.explorer.actions")
local zk = require("snacks.zk")

local M = {}

setmetatable(M, { __index = explorer_actions }) -- Inherit from snacks.explorer.actions

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
  table.sort(items, function(a, b)
    return a.desc < b.desc
  end)
  vim.ui.select(items, { prompt = "zk query", format_item = format_item }, function(item)
    if not item then
      return
    end
    item.input(zk.notebook_path, id, function(res)
      zk.opts.query = res
      zk.update_picker_title()
      require("snacks.zk.watch").refresh()
    end)
  end)
end

---Reset query
M.actions.zk_reset_query = function()
  zk.opts.query = zk.opts.default_query
  zk.update_picker_title()
  require("snacks.zk.watch").refresh()
end

return M

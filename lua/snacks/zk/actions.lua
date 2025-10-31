local explorer_actions = require("snacks.explorer.actions")
local zk = require("snacks.zk")
local zk_watch = require("snacks.zk.watch")

local M = {}

setmetatable(M, { __index = explorer_actions }) -- Inherit from snacks.explorer.actions

local function format_item(item)
  return item.desc
end

local function get_current_id()
  local id
  local picker = Snacks.picker.get({ source = "zk" })[1]
  if picker and not picker.closed then
    local item = picker:current()
    id = item.file
  end
  return id
end

---Change the query dynamically
M.actions.zk_change_query = function()
  local id = get_current_id()
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
    local picker = Snacks.picker.get({ source = "zk" })[1]
    local cwd = picker and picker:cwd() or zk.notebook_path
    item.input(cwd, id, function(res)
      zk.opts.query = res
      zk.update_picker_title()
      zk_watch.refresh(function()
        print(string.format("zk_change_query: id: %s / cwd: %s", id, cwd))
        zk.reveal({ file = id })
      end)
    end)
  end)
end

---Reset query
M.actions.zk_reset_query = function()
  local id = get_current_id()
  local picker = Snacks.picker.get({ source = "zk" })[1]
  local cwd = picker and picker:cwd() or zk.notebook_path
  zk.opts.query = zk.opts.default_query
  zk.update_picker_title()
  zk_watch.refresh(function()
    print(string.format("zk_reset_query: id: %s / cwd: %s", id, cwd))
    zk.reveal({ file = id })
  end)
end

---Change the sort dynamically
M.actions.zk_change_sort = function()
  local id = get_current_id()

  local items = {}
  for _, item in pairs(require("snacks.zk.sorters")) do
    table.insert(items, item)
  end
  table.sort(items, function(a, b)
    return a.desc < b.desc
  end)
  vim.ui.select(items, { prompt = "zk sort", format_item = format_item }, function(item)
    if not item then
      return
    end
    if type(item.sort) == "table" then -- snacks.picker.zk.sort.Fields[]
      zk.opts.sort = { fields = item.sort }
    elseif type(item.sort) == "function" then -- "snacks.picker.zk.sort.Func"
      zk.opts.sort = item.sort
    end
    zk.update_picker_title()
    zk_watch.refresh(function()
      zk.reveal({ file = id })
    end)
  end)
end

---Reset sort
M.actions.zk_reset_sort = function()
  local id = get_current_id()
  zk.opts.sort = zk.opts.default_sort
  zk.update_picker_title()
  zk_watch.refresh(function()
    zk.reveal({ file = id })
  end)
end

return M

local Tree = require("snacks.zk.tree")
local zk = require("snacks.zk")

local M = require("snacks.explorer.actions") -- Merged with explorer's action.  -- FIX: Avoid direct merge! Use inheritance instead!

local function format_item(item)
  return item.desc
end

---Add query description to picker title
local function set_picker_title(query_desc)
  local picker = Snacks.picker.get({ source = "zk" })[1]
  local suffix = ""
  if query_desc then
    suffix = ": " .. query_desc
  end
  picker.title = "Zk" .. suffix
  -- local title = { {"Zk", "FloatTitle"}, { " " .. res.desc .. " ", "SnacksPickerToggle" } } -- TODO: If possible, set title with hl
  -- picker.title = title
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
      zk.query = res
      set_picker_title(res.desc)
      require("snacks.zk.watch").refresh()
    end)
  end)
end

M.actions.zk_reset_query = function()
  zk.query = zk.default_query
  set_picker_title()
  require("snacks.zk.watch").refresh()
end

return M

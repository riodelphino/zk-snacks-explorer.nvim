local M = {}

---Get zk picker
---@return snacks.Picker?
M.get_picker = function()
  return Snacks.picker.get({ source = "zk" })[1]
end

---Focus on pickers window
---@param win string? "input"|"list"|"preview"
---@param opts? {show?: boolean}
M.focus = function(win, opts)
  local picker = M.get_picker()
  if picker then
    return picker:focus(win, opts)
  end
end

return M

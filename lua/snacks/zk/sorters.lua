local M = {}

---@param a snacks.picker.explorer.Node
---@param b snacks.picker.explorer.Node
---@return boolean
M.title = function(a, b)
  local notes = require("snacks.zk").notes_cache
  local an = notes[a.path] or nil
  local bn = notes[b.path] or nil
  local at = an and an.title
  local bt = bn and bn.title
  local a_has_title = (at ~= nil)
  local b_has_title = (bt ~= nil)
  local a_is_dot = (a.name:sub(1, 1) == ".")
  local b_is_dot = (b.name:sub(1, 1) == ".")
  if a.dir ~= b.dir then
    return a.dir
  end
  if a_is_dot ~= b_is_dot then
    return not a_is_dot
  end
  if a_has_title ~= b_has_title then
    return a_has_title
  end
  if a_has_title and b_has_title then
    return at < bt
  end
  return a.name < b.name
end

---@param a snacks.picker.explorer.Node
---@param b snacks.picker.explorer.Node
---@return boolean
M.created = function(a, b) -- FIX: error
  local notes = require("snacks.zk").notes_cache
  local an = notes[a.path] or nil
  local bn = notes[b.path] or nil
  local ac = an and an.created
  local bc = bn and bn.created
  return ac < bc
end

---@param a snacks.picker.explorer.Node
---@param b snacks.picker.explorer.Node
---@return boolean
M.modified = function(a, b)
  return a.name < b.name
end

return M

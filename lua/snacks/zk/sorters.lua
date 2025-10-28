local notes = require("snacks.zk").notes_cache

local M = {}

-- TODO: Consider asc / desc

-- TODO: Move to README.md as function type sample.
-- ---@type snacks.picker.zk.Sort
-- M.title = {
--   desc = "Default",
--   sort = function(a, b)
--     local an = notes[a.path] or nil
--     local bn = notes[b.path] or nil
--     local at = an and an.title
--     local bt = bn and bn.title
--     local a_has_title = (at ~= nil)
--     local b_has_title = (bt ~= nil)
--     local a_is_dot = (a.name:sub(1, 1) == ".")
--     local b_is_dot = (b.name:sub(1, 1) == ".")
--     if a.dir ~= b.dir then
--       return a.dir
--     end
--     if a_is_dot ~= b_is_dot then
--       return not a_is_dot
--     end
--     if a_has_title ~= b_has_title then
--       return a_has_title
--     end
--     if a_has_title and b_has_title then
--       return at < bt
--     end
--     return a.name < b.name
--   end,
-- }

---@type snacks.picker.zk.Sort
M.title = {
  desc = "Title (asc)",
  sort = { "dir", "hidden:desc", "!zk.title", "zk.title", "name" },
}

---@type snacks.picker.zk.Sort
M.title_desc = {
  desc = "Title (desc)",
  sort = { "dir", "hidden:desc", "!zk.title", "zk.title:desc", "name:desc" },
}

---@type snacks.picker.zk.Sort
M.created = {
  desc = "Created (asc)",
  sort = { "dir", "hidden:desc", "created" },
}

---@type snacks.picker.zk.Sort
M.created_desc = {
  desc = "Created (desc)",
  sort = { "dir", "hidden:desc", "created:desc" },
}

---@type snacks.picker.zk.Sort
M.modified = {
  desc = "Modified (asc)",
  sort = { "dir", "hidden:desc", "modified" },
}

---@type snacks.picker.zk.Sort
M.modified_desc = {
  desc = "Modified (desc)",
  sort = { "dir", "hidden:desc", "modified!" },
}

return M

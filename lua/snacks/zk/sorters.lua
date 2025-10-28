local notes = require("snacks.zk").notes_cache

local M = {}

-- TODO: Consider asc / desc

---@type snacks.picker.zk.Sort
M.title = {
  desc = "Title (asc)",
  sort = { "dir", "hidden:desc", "zk.title", "name" },
}

---@type snacks.picker.zk.Sort
M.title_desc = {
  desc = "Title (desc)",
  sort = { "dir", "hidden:desc", "zk.title:desc", "name:desc" },
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

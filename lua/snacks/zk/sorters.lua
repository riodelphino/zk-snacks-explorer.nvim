local notes = require("snacks.zk").notes_cache

local M = {}

-- TODO: Consider asc / desc

---@type snacks.picker.zk.Sort
M.title = {
  desc = "Title ",
  sort = { "dir", "hidden:desc", "zk.title", "name" },
}

---@type snacks.picker.zk.Sort
M.title_desc = {
  desc = "Title (-)",
  sort = { "dir", "hidden:desc", "zk.title:desc", "name:desc" },
}

---@type snacks.picker.zk.Sort
M.created = {
  desc = "Created ",
  sort = { "dir", "hidden:desc", "zk.created" },
}

---@type snacks.picker.zk.Sort
M.created_desc = {
  desc = "Created (-)",
  sort = { "dir", "hidden:desc", "zk.created:desc" },
}

---@type snacks.picker.zk.Sort
M.modified = {
  desc = "Modified ",
  sort = { "dir", "hidden:desc", "zk.modified" },
}

---@type snacks.picker.zk.Sort
M.modified_desc = {
  desc = "Modified (-)",
  sort = { "dir", "hidden:desc", "zk.modified!" },
}

return M

---@meta

---@class snacks.picker.zk.Query
---@field desc string
---@field query table?
---@field input function?

---@class snacks.picker.zk.Config : snacks.picker.explorer.Config
---@field select table?
---@field sort (table|function)
---@field sorters table?
---@field default_sorter (string|table)?
---@field query snacks.picker.zk.Query?
---@field default_query snacks.picker.zk.Query?
---@field queries snacks.picker.zk.Query[]?
---@field query_postfix string?

---@class snacks.picker.zk.Node : snacks.picker.explorer.Node
---@field sort string? -- A string used for sorting in the tree view (This field works alone)
---@field zk table?

---@class snacks.picker.zk.Item : snacks.picker.explorer.Item
---@field hidden boolean?
---@field zk table?

---@class snacks.picker.zk.Tree : snacks.picker.explorer.Tree

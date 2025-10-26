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
---@field sort_base string? -- A base string used for sorting in the tree view with other fields
---@field title string? -- zk title
---@field zk table? -- All zk fields fetched by zk.api.list -- DEBUG: Should flattern it like Item?

---@class snacks.picker.zk.Item : snacks.picker.explorer.Item
---@field hidden boolean?
---@field filename string?
---@field filenameStem string?
---@field path string?
---@field absPath string?
---@field title string?
---@field lead string?
---@field body string?
---@field snippets string?
---@field rawContent string?
---@field wordCount number?
---@field tags (string|table)?
---@field metadata table?
---@field created string?
---@field modified string?
---@field checksum string?

---@class snacks.picker.zk.Tree : snacks.picker.explorer.Tree

---@meta

---@class snacks.picker.zk.Config : snacks.picker.explorer.Config
---@field select table?
---@field default_sorter string?
---@field sorters table?
---@field default_query string?
---@field queries table?
---@field query_postfix string?

---@class snacks.picker.zk.Node : snacks.picker.explorer.Node
---@field sort string?
---@field title string? -- zk title
---@field zk table? -- All zk fields fetched by zk.api.list

---@class snacks.picker.zk.Item : snacks.picker.explorer.Item
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

---@meta

---@class snacks.picker.explorer.Item: snacks.picker.finder.Item -- DEBUG: NEED THIS?

---@class snacks.picker.zk.Config : snacks.picker.explorer.Config
---@field enabled boolean|(fun():boolean)?
---@field select table?
---@field sort snacks.picker.zk.sort.Config?
---@field default_sort snacks.picker.zk.sort.Config?
---@field sorters table?
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

---@class snacks.picker.zk.Query
---@field desc string
---@field query table?
---@field input function?

---@class snacks.picker.zk.Sort
---@field desc string
---@field sort snacks.picker.zk.sort.Config

---@class snacks.picker.zk.sort.Field
---@field name string
---@field desc boolean
---@field len boolean?
---@field has boolean?

---@class snacks.picker.zk.formatters.file.zk.Config
---@field filename? fun(item: snacks.picker.zk.Item, picker: snacks.Picker): snacks.picker.Highlight[]
---@field transform? snacks.picker.zk.formatters.file.zk.Transform

---@class snacks.picker.zk.formatters.file.zk.Transform
---@field icon? snacks.picker.zk.formatters.file.zk.transform.Icon
---@field text? snacks.picker.zk.formatters.file.zk.transform.Text

---@alias snacks.picker.zk.sort.Func fun(a: snacks.picker.zk.Node|snacks.picker.zk.Item, b: snacks.picker.zk.Node|snacks.picker.zk.Item): boolean
---@alias snacks.picker.zk.sort.Config (string|snacks.picker.zk.sort.Field)[]|snacks.picker.zk.sort.Func)

---@alias snacks.picker.zk.formatters.file.zk.transform.Icon fun(item: snacks.picker.zk.Item, note: table?, icon: string, hl: string): string, string
---@alias snacks.picker.zk.formatters.file.zk.transform.Text fun(item: snacks.picker.zk.Item, note: table?, base: string?, base_hl: string, dir_hl: string): string?, string, string

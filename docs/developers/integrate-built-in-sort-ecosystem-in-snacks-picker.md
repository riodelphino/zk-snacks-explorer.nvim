
# Integrate built-in sort ecosystem in snacks.picker


How `snacks-zk-explorer.nvim` integrates with the built-in sort ecosystem in `snacks.picker`.


## Assignments

- Make explorer() function evaluates the `sort = ...` config.
- Bridge between `Node` and `Item`.


### Differencies between explorer() and search() functions

The functions `M.explorer()` and `M.search()` in `lua/snacks/sources/explorer.lua` are fundamentally different.

| Function     | Sort Logic | Config 'sort = ...' is | Class of the entries         |
| ------------ | ---------- | ------------------- | ---------------------------- |
| M.explorer() | Own way    | ignored             | @snacks.picker.explorer.Node |
| M.search()   | Use config | evaluated           | @snacks.picker.Item          |

1. Collect `Node` list from the filesystem (kept only inside)
2. Generate `Item` list based on `Node` (copied and molded)
3. The tree is shown based on `Item` list.


### Differencies between Node and Item

Item and Node are similar but have differencies in some fileds.
(e.g. `node.path` <-> `item.file`)

| explorer.Node | Item      | explorer.Item | MEMO             |
| ------------- | --------- | ------------- | ---------------- |
| node.dir      | -         | item.dir      | Directory or not |
| node.path     | item.file | item.file     | The full path        |
| -             | -         | item.sort     | A string for sort  |
| node.parent   | -         | item.parent   | The parent           |


## Solutions

### Points:

Sort config is designed to accept two ways:
  - `sort = { fields = { "sort" } }`
  - `sort = function(a, b) ... end`

However, the sort ecosystem: 
  - Only accepts `snacks.picker.Item` list
  - Does not accepts `snacks.picker.explorer.Node` list


### Solution 1: Duplicate search function

Duplicate and modify `search()` as `zk()`
It's from `lua/snacks/sources/zk.lua` in `snacks-zk-explorer.nvim`.
* If the 2nd solution does not work.


### Solution 2: Accepts both Node and Item

Make sort function accepts both Node and Item.
--> Finally finished.

The entries(`Node`) should be sorted in `Tree:walk()`

A sample sort function (accepts both Node and Item):
```lua
---@type a @snacks.picker.explorer.Node|@snacks.picker.Item
---@type b @snacks.picker.explorer.Node|@snacks.picker.Item
local sort = function(a, b)
  if type(a) == "@snacks.picker.Node" then
    a_full_path = a.path or a.file
    b_full_path = b.path or b.file
  end
  ...
end
```

## Notes

### Node and Item class definitions

@snacks.picker.explorer.Node:
```lua
---@class snacks.picker.explorer.Node
---@field path string
---@field name string
---@field hidden? boolean
---@field status? string merged git status
---@field dir_status? string git status of the directory
---@field ignored? boolean
---@field type "file"|"directory"|"link"|"fifo"|"socket"|"char"|"block"|"unknown"
---@field dir? boolean
---@field open? boolean wether the node should be expanded (only for directories)
---@field expanded? boolean wether the node is expanded (only for directories)
---@field parent? snacks.picker.explorer.Node
---@field last? boolean child of the parent
---@field utime? number
---@field children table<string, snacks.picker.explorer.Node>
---@field severity? number
```

@snacks.picker.Item:
```lua
---@class snacks.picker.Item
---@field [string] any
---@field idx number
---@field score number
---@field frecency? number
---@field score_add? number
---@field score_mul? number
---@field source_id? number
---@field file? string
---@field text string
---@field pos? snacks.picker.Pos
---@field loc? snacks.picker.lsp.Loc
---@field end_pos? snacks.picker.Pos
---@field highlights? snacks.picker.Highlight[][]
---@field preview? snacks.picker.Item.preview
---@field resolve? fun(item:snacks.picker.Item)
```
 (extends)

@snacks.picker.finder.Item
```lua
---@class snacks.picker.finder.Item: snacks.picker.Item
---@field idx? number
---@field score? number
```
 (extends)

@snacks.picker.explorer.Item
```lua
---@class snacks.picker.explorer.Item: snacks.picker.finder.Item
---@field file string
---@field dir? boolean
---@field parent? snacks.picker.explorer.Item
---@field open? boolean
---@field last? boolean
---@field sort? string
---@field internal? boolean internal parent directories not part of fd output
---@field status? string
```

#### Just for references

@snacks.picker.explorer.Filter
```lua
---@class snacks.picker.explorer.Filter
---@field hidden? boolean show hidden files
---@field ignored? boolean show ignored files
---@field exclude? string[] globs to exclude
---@field include? string[] globs to exclude
```


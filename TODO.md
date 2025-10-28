
# TODO


## SOLUTION 1

search() をコピペする。

* もし2が動かなければで。

## SOLUTION 2

sorter 関数を、Node/Item どちらでも受け取れるようにする？
--> どうにか実現できた。

順番的には、
  1. 内部的な Node
  2. Tree 表示は Item
なのだが、Node の Tree:walk() の中でソートする必要がある。

`node.path` <-> `item.file` と違う点も考慮し、 以下のように、Node / Item どちらでもOKとした。

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

 
対応表:
| explorer.Node | Item      | explorer.Item | MEMO             |
| ------------- | --------- | ------------- | ---------------- |
| node.dir      | -         | item.dir      | is directory?    |
| node.path     | item.file | item.file     | full path        |
| -             | -         | item.sort     | string for sort  |
| node.parent   | -         | item.parent   | parent node/item |
- ディレクトリ判定: OK
- parent 取得: OK
- sort フィールド:
  - うーん、explorer.Node に無いけど、zk.Node に継承・拡張して、無理やり sort を作っておくか？
  - 作ったとしても、実際に sort 実行は、手動でコード書くしかないかも？
  - あ、sort 関数を return してくれる関数があったよね！

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


参考まで
@snacks.picker.explorer.Filter
```lua
---@class snacks.picker.explorer.Filter
---@field hidden? boolean show hidden files
---@field ignored? boolean show ignored files
---@field exclude? string[] globs to exclude
---@field include? string[] globs to exclude
```
@snacks.picker.finder.Item:
```lua
---@class snacks.picker.finder.Item: snacks.picker.Item
---@field idx? number
---@field score? number

```

## 注意点

- [ ] この TODO.md を DEVELOPERS.md と zk TODO に移行する
- [ ] search 時に親フォルダが子ファイルより下に来てしまう
- [ ] change_sort() を完成させる
- [ ] notes_cache を opts に含める？ (M.notes_cacheを廃止)

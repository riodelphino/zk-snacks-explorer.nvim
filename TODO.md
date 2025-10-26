
# TODO


## 検討中

Tree:get の中で手動で sorter を呼ぶのをいったんやめてます。
```lua
Before:  (item.sort あり)                 After: (item.sort なし)

󰝰 zk-md-tests                             󰝰 zk-md-tests                         
 ├╴󰉋 daily                                ├╴󰉋 assets                            
 ├╴󰝰 tests                                ├╴󰉋 daily                             
 │ ├╴󰉋 others                             ├╴󰝰 tests                             
 │ ├╴󱁽 lsp                               │ ├╴󰉋 dir                           ○ 
 │ ├╴󰉋 title                         ○    │ ├╴󰉋 git                             
 │ ├╴󰝰 sort                               │ ├╴󰉋 filter                          
 │ │ ├╴󰍔 D                                │ ├╴󰉋 title                         ○ 
 │ │ ├╴󰉋 a                                │ ├╴󰉋 filetype                        
 │ │ ├╴󰉋 b                                │ ├╴󰉋 tag                             
 │ │ ├╴󰉋 c                                │ ├╴󰉋 yaml                            
 │ │ ├╴󰍔 A                                │ ├╴󰉋 hidden                          
 │ │ ├╴󰍔 C.md                             │ ├╴󰝰 sort                            
 │ │ ├╴󰍔 A.md                             │ │ ├╴󰍔 D                             
 │ │ ├╴󰍔 B                                │ │ ├╴󰍔 D.md                          
 │ │ ├╴󰍔 D.md                             │ │ ├╴󰉋 c                             
 │ │ ├╴󰍔 B.md                             │ │ ├╴󰉋 a                             
 │ │ └╴󰍔 C                                │ │ ├╴󰍔 A                             
 │ ├╴󰉋 hidden                             │ │ ├╴󰍔 A.md                          
 │ ├╴󰉋 filter                             │ │ ├╴󰍔 B                             
 │ ├╴󰉋 yaml                               │ │ ├╴󰉋 b                             
 │ ├╴󰉋 filetype                           │ │ ├╴󰍔 B.md                          
 │ ├╴󰉋 tag                                │ │ ├╴󰍔 C                             
 │ ├╴󰉋 dir                           ○    │ │ └╴󰍔 C.md                          
 │ └╴󰉋 git                                │ ├╴󱁽 lsp                            
 ├╴󰝰 notes                                │ └╴󰉋 others                          
 │ ├╴󰍔 First note in notes dir            ├╴󰝰 notes                             
 │ └╴󰍔 Second note in notes dir           │ ├╴󰍔 First note in notes dir         
 ├╴ zk-md-tests                          │ └╴󰍔 Second note in notes dir        
 └╴󰉋 assets                               └╴ zk-md-tests                        
```

● item.sort あり
  ❌️ dir file もソートされておらずバラバラ
  ❌️ title も考慮されていない

● item.sort なし
  ⭕️ ルートの dir file は sort されているが
  ❌️ サブディレクトリの dir file はバラバラ
  ❌️ title は考慮されていない

⚠️ 現状では、`item.sort` と `sort = { fields = { "sort" } }` がかえってオーダーを壊している。 
⚠️ が、いずれにせよ、オーダーは正しくない。

node -> item なのだが、node の時点でソートする必要がある、となると、`sort = { fields = { "sort" } }` の built-in 系はそのままでは使えない。
node を item に変換して...とかも面倒くさそうだ。 `node.path` <-> `item.file` と違うし。

```lua
---@type a @snacks.picker.explorer.Node|@snacks.picker.Item
---@type b @snacks.picker.explorer.Node|@snacks.picker.Item
M.sort_test = function(a, b)
  if type(a) == "@snacks.picker.Node" then
    a.file = a.path
    b.file = b.path
  end
  ...
end
```
のように、Node / Item どちらでもOKとするか？


## SOLUTION 1

search() をコピペする、しか道がなさそうだ。
- [ ] notes_cache から title や created など 全フィールドを、 item.zk or node.zk にぜんぶ付与してしまおうか？

## SOLUTION 2

sorter 関数を、Node/Item どちらでも受け取れるようにする？
--> どうにか実現できた。

```lua
-- sort フィールドを取得する関数 (item/node両対応)
---@param entry snacks.picker.explorer.Node|snacks.picker.explorer.Item
function M.get_sort_string(entry) end

return M

-- sort フィールドにセット
item|node.sort = M.get_sort_string(item|node)
-- sort 実行
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

- [ ] opts.sort に集約する (init.lua の M.sort は使わない)
- [ ] default_sort を利用する
- [ ] change_sort() を完成させる
- [ ] notes_cache を opts に含める？ (M.notes_cacheを廃止)
- [ ] search 時に親フォルダが子ファイルより下に来てしまう
- [ ] ディレクトリは無条件で open されているが、expand 設定に従うこと
- [ ] actions が有効か？
- [x] / キーでのサーチ状態になっていないか？
- [x] git / diagnostics が有効か？

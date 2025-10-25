
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


## Conclusion

search() をコピペする、しか道がなさそうだ。

### 注意点

- [ ] ディレクトリは無条件で open されているが、expand 設定に従うこと
- [ ] git / diagnostics が有効か？
- [ ] actions が有効か？
- [ ] / キーでのサーチ状態になっていないか？


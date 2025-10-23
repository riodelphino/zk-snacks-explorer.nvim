# TODO

- [x] zk
  - [ ] zk_opts, zk_source の表記ゆれを統一
  - [ ] Action:
      - [ ] action.change_sort() を追加？
      - [ ] select {} もcreatedとか加えないと？
  - [ ] tree.lua Tree クラス
      - [ ] 現状では snacks.explorer.tree に無理やり関数を追加してる
      - [ ] 危険なので、きちんと継承させる
      - [ ] get_zk -> get / walk_zk -> walk に戻す
      - [ ] [NOTES](#notes) を参考
  - [-] ユーザー向けの config を追加
    - [ ] setup 時にマージできるのか？ snacks が source.zk を自動読み込みしてるんだよ？
    - [ ] てか、sort とか format って config から読み込んでないやん？
      - [ ] config に値があればそちらを読み、なければ sort.lua や format.lua からロードする、とか？
    - [ ] sort:
      - [ ] `tree.lua` -> `zk_sorter = require("snacks.zk.sort")` -> `table.sort(children, zk_sorter)`
      - [ ] explorer の作法から外れるが、sort = に指定した関数を walk_zk 内で適用する、もし関数ではなくテーブルなら、その順番でソートする、とかにできるかなぁ？
      - [ ] しかも、 { fields = { "sort:asc", { name = "idx", order = "asc" } } } とかの場合も考慮するの？大変じゃね？
    - [ ] format:
      - [ ] `format = zk_format.zk_file`
      - [ ] ここでなんとかできるかなぁ
    - [ ] matcher: `matcher = { sort_empty = false, fuzzy = true }`
       - [ ] これは普通にそのまま適用されるからOK
    - [x] queries
      - [x] 保存先: lua/snacks/zk/init.lua の local M.query
      - [x] notebook_path の保存をしてないなぁ。今は自動で resolve させてる。query で使うかも？
      - [ ] 現在適用中の query.desc を表示する
      - [ ] query list の順番を アルファベット順に
      - [ ] default_query を opts に移設。後に変更可能とする。=~ "All" の判定も default_query との比較に？
    - [ ] tree.lua
      - [ ] 直接拡張をせず、新しいクラスとして拡張すべき。
      - [ ] また、walk_zk -> walk, get_zk -> get に戻してよい
  - [ ] Replace the screenshot images (based on [riodelphino/zk-md-tests](https://github.com/riodelphino/zk-md-tests))


## 保留
  - [ ] picker 名称
    - [ ] `zk` だと、zk-nvim integrate の snacks_picker のと混同しそう。`zk_explorer` が良いかな？
    - [ ] source 名を zk -> zk_explorer に変更？
    - [ ] そうすると 関数名も `zk_explorer` or `explorer_zk` か？
    - [ ] -> 長過ぎるのが難点

- [ ] OTHERS
  - [ ] Snacks.picker.util.truncpath() とは？pathを変換するだと？表示名の変換に使えるのか？
  - [ ] explorer の setup() は、なぜ config/sources.lua にある explorer の source 設定を再度上書きする必要があるのだろう？
    - [ ] filename_only が tree で上書きされてる。この影響が zk にも出てる？


## NOTES

tree.lua:
直接拡張をせず、新しいクラスとして拡張すべき。また、walk_zk -> walk, get_zk -> get に戻してよい
```lua
---@class snacks.zk.Tree : snacks.picker.explorer.Tree
local Tree = {}
local ExplorerTree = require("snacks.explorer.tree")

-- メタテーブルで継承
setmetatable(Tree, { __index = ExplorerTree })

-- コンストラクタをオーバーライド
function Tree.new(...)
  local self = ExplorerTree.new(...)
  return setmetatable(self, { __index = Tree })
end

-- ZK専用メソッドを追加
function Tree:walk_zk(node, fn, opts)
  -- 実装
end

function Tree:get_zk(cwd, cb, opts)
  -- 実装
end

return Tree
```

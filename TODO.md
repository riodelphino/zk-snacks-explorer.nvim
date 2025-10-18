# TODO

- [x] Snacks.zk として使えるようにしたい
- [x] 最初から pickers リストに表示されるように
- [-] zk
   - [x] setup か open で notes_cache を取得。
   - [x] format で title を表示してみる
   - [x] dir -> title -> filename / normal -> dotfile でソート
   - [ ] 全ファイルを表示する (なぜか欠けてるのがある) (-> snacks.explorer を表示後は全ファイル表示される。なぜ？)
   - [ ] ツリーのノードアイコンが表示されない
   - [ ] 'l' キーでフォルダを開く
      - [ ] explorer で展開済みじゃないとひらかない
      - [ ] 開いた子要素が dir/file.md のようになってしまう


## lua/snacks/zk/tree.lua

Customized version of `lua/snacks/explorer/tree.lua` from snacks

### walk_zk と get_zk

get_zk が逐次ファイルを walk_zk で取得して処理していくが、
walk_zk が処理している時点で、処理対象リストがすでに意図した sort になっている必要がある。


## ファイルの役割とディレクトリ構造

### lua/snacks/zk/init.lua

zk のエントリーポイント。
下の explorer/init.lua の M をマージ。その同階層の action.lua などを流用している。はず。


### lua/snacks/explorer/init.lua

explorer のエントリーポイント。ユーザー利用のインターフェースを提供
action.lua / diagnositics.lua / git.lua / tree.lua / watch.lua


### lua/snacks/picker/source/explorer.lua

- ツリー型ファイル探索
   - ファイルシステムをツリー構造で表示・操作
   - ディレクトリの開閉状態を管理
   - 階層的なファイル表示（親子関係の追跡）
- 統合機能
   - Git 統合: ファイルの変更状態を表示
   - 診断統合: LSP の診断情報を表示
   - 自動更新: ファイル変更、ディレクトリ変更、診断変更を検知して更新
   - カスタムマッチャー: 検索時に親ディレクトリも自動的にマッチに含める
- search   関数 = ツリー構造でファイルを検索
- explorer 関数 = ツリー構造でファイルを表示

* これを finder = "explorer" のように指定するようだ。

## picker 登録

require('snacks.picker').pick(source_name, source_opts) で登録。
内部的に require("snacks.picker.core.picker").new() を呼び出している

## ソート

`lua/snacks/picker/sort.lua` が built-in の sorter `default` と `idx` の在り処。

> [!Caution]
> 残念ながら、explorer ではこれら全部まったく使えない。
> Tree:get() つまりその内部の Tree.walk() が読み込んだ順番そのままで表示される。
> sort オプションは一切考慮されない。


### ２種類の取りうる値


```lua
-- 基本のソート
local source = {
   sort = { fields = { 'sort' } }
}
```
```lua
-- デフォルト値
sort = { 
   fields = { 
      { name = "score", desc = true },  -- スコア降順
      "idx"                             -- 追加順
   }
}
```

#### 関数を直接セット
```lua
---@alias snacks.picker.sort fun(a:snacks.picker.Item, b:snacks.picker.Item):boolean
```
とあるので、
```lua
sort = function(a, b) ... end
```
と直接指定も可能。

#### built-in の sorter を指定


```lua
-- item.sort フィールドで昇順ソート
sort = { fields = { 'sort' } }

-- item.sort フィールドで昇順ソート (明示的)
sort = { fields = { 'sort:asc' } }

-- item.sort フィールドで降順ソート
sort = { fields = { 'sort:desc' } }

-- item の複数フィールドでソート
sort = {
   fields = {
      "dir:desc",   -- item.dir で降順（ディレクトリが先）
      "title",      -- item.title で昇順
      "idx"         -- 同じなら item.idx（追加順）}
   }
}

-- item.title フィールドの文字列の長さでソート
sort = { 
   fields = { 
      "#title"
   }
}

-- テーブルで指定
sort = { 
  fields = { 
    { name = "score", desc = true },  -- スコアが高い順
    "title"                           -- 同じスコアなら title 順
  }
}

-- テーブルで詳細指定
sort = { 
   fields = {
      name = "field_name", 
      desc = true,   -- 降順
      len = true     -- 長さでソート
   }
}
```

## 方針

なるべく、流用できるものは流用する。M をマージ出来るものはマージする。

- finder は "explorer" を流用
- format を追加して変更すれば、表示項目名をカスタムできる
- sort はどうする？

## その他

```lua
M.explorer = {
  finder = "explorer",
```
この finder は、lua/snacks/picker/source/*.lua の中で M.explorer のように設定されているものたち。

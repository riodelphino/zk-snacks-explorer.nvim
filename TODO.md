# TODO

- [ ] Snacks.zk として使えるようにしたい
- [ ] 最初から pickers リストに表示されるように
- [ ] zk
   - [ ] setup か open で notes_cache を取得。
   - [ ] format で title を表示してみる

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

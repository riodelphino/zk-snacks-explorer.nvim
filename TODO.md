# TODO


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


## 方針

なるべく、流用できるものは流用する。M をマージ出来るものはマージする。



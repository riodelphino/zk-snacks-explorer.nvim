# TODO

- [x] init/setup
  - [x] Snacks.zk として使えるようにしたい
  - [x] 最初から pickers リストに表示されるように
  - [x] 一回目の keymap での実行時、すぐCloseされてしまう
  - [x] state など、explorer を流用し過ぎてる？ 問題が発生するかも？ -> state も zk 用で行く
- [-] zk
  - [x] setup か open で notes_cache を取得。
  - [x] format で title を表示してみる
  - [x] dir -> title -> filename / normal -> dotfile でソート
  - [x] 全ファイルを表示する (なぜか欠けてるのがある) (-> snacks.explorer を表示後は全ファイル表示される。なぜ？)
  - [x] ツリーのノードアイコンが表示されない
  - [x] 'l' キーでフォルダを開く
    - [x] explorer で展開済みじゃないとひらかない
    - [x] 開いた子要素が dir/file.md のようになってしまう
  - [x] Search
    - [x] title も追うように
    - [x] fuzzy 検索のモードがおかしい。 'd a' と入れると、'ad' にヒットする
  - [x] ファイル・フォルダの新規作成・削除・リネーム・移動時に、最新情報に更新されない -> zk.api.index() で解決
  - [ ] zk_opts, zk_source の表記ゆれを統一
  - [ ] ユーザー向けの config を追加
  - [ ] actions 追加？
  - [ ] queries 的なのを追加？
  - [ ] picker 名称
    - [ ] `zk` だと、zk-nvim integrate の snacks_picker のと混同しそう。`zk_explorer` が良いかな？
    - [ ] そうすると 関数名も `zk_explorer` or `explorer_zk` か？
  - [x] setup() が２つあって混乱。
    - [x] `snacks/picker/source/explorer.lua` の setup() (configを上書きしてる)
    - [x] `snacks/explorer/init.lua` の setup() 何やってるこれ？
    - [x] たぶんうまく動作している。が、正直よくわからない。
  - [ ] フィルターって query みたいなもの？
- [ ] test
  - [ ] テスト用のフォルダ＆ファイルを作成
- [ ] OTHERS
  - [ ] Snacks.picker.util.truncpath() とは？pathを変換するだと？表示名の変換に使えるのか？
  - [ ] explorer の setup() は、なぜ config/sources.lua にある explorer の source 設定を再度上書きする必要があるのだろう？
    - [ ] filename_only が tree で上書きされてる。この影響が zk にも出る。



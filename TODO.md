# TODO

- [ ] init/setup
   - [x] Snacks.zk として使えるようにしたい
   - [x] 最初から pickers リストに表示されるように
   - [ ] 一回目の keymap での実行時、すぐCloseされてしまう
   - [ ] state など、explorer を流用し過ぎてる？ 問題が発生するかも？
- [x] zk
   - [x] setup か open で notes_cache を取得。
   - [x] format で title を表示してみる
   - [x] dir -> title -> filename / normal -> dotfile でソート
   - [x] 全ファイルを表示する (なぜか欠けてるのがある) (-> snacks.explorer を表示後は全ファイル表示される。なぜ？)
   - [x] ツリーのノードアイコンが表示されない
   - [x] 'l' キーでフォルダを開く
      - [x] explorer で展開済みじゃないとひらかない
      - [x] 開いた子要素が dir/file.md のようになってしまう
   - [ ] ユーザー向けの config を追加
   - [ ] Search が title も追うように
   - [ ] actions 追加？
   - [ ] queries 的なのを追加？
   - [ ] picker 名称
      - [ ] `zk` だと、zk-nvim integrate の snacks_picker のと混同しそう。`zk_explorer` が良いかな？
      - [ ] そうすると 関数名も `zk_explorer` or `explorer_zk` か？
   - [ ] setup() が２つあって混乱。
      - [ ] `snacks/picker/source/explorer.lua` の setup() (configを上書きしてる)
      - [ ] `snacks/explorer/init.lua` の setup() 何やってるこれ？
   - [ ] フィルターって query みたいなもの？
- [ ] test
   - [ ] テスト用のフォルダ＆ファイルを作成

- [ ] Snacks.picker.util.truncpath() とは？pathを変換するだと？表示名の変換に使えるのか？
- [ ] explorer の setup() は、なぜ config/sources.lua にある explorer の source 設定を再度上書きする必要があるのだろう？
   - [ ] filename_only が tree で上書きされてる。この影響が zk にも出る。



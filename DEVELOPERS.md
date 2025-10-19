# DEVELOPERS

Some notes for developers to help understanding `pickers` in `snacks.nvim` and `zk` picker in `snacks-zk.nvim`.

## Structure

### zk (this repo)

#### Entry Point

- lua/snacks/zk/init.lua

Provides UI functions: `setup()`, `open()`, `reveal()`
Merges `M` in `lua/snacks/explorer/init.lua`, then reuses Actions (maybe).


### explorer (built-in)

#### Entry Point 1

- lua/snacks/source/explorer.lua

What's this?


#### Entry Point 2

- lua/snacks/explorer/init.lua

Provides UI functions: `setup()`, `open()`, `reveal()`

config を以下のようにマージ・上書きしてるのが気になる。
```lua
---@param opts snacks.picker.explorer.Config
function M.setup(opts)
  local searching = false
  local ref ---@type snacks.Picker.ref
  return Snacks.config.merge(opts, {
    actions = {
      confirm = Actions.actions.confirm,
    },
    filter = {
      --- Trigger finder when pattern toggles between empty / non-empty
      ---@param picker snacks.Picker
      ---@param filter snacks.picker.Filter
      transform = function(picker, filter)
        ref = picker:ref()
        local s = not filter:is_empty()
        if searching ~= s then
          searching = s
          filter.meta.searching = searching
          return true
        end
      end,
    },
    matcher = {
      --- Add parent dirs to matching items
      ---@param matcher snacks.picker.Matcher
      ---@param item snacks.picker.explorer.Item
      on_match = function(matcher, item)
        if not searching then
          return
        end
        local picker = ref.value
        if picker and item.score > 0 then
          local parent = item.parent
          while parent do
            if parent.score == 0 or parent.match_tick ~= matcher.tick then
              parent.score = 1
              parent.match_tick = matcher.tick
              parent.match_topk = nil
              picker.list:add(parent)
            else
              break
            end
            parent = parent.parent
          end
        end
      end,
      on_done = function()
        if not searching then
          return
        end
        local picker = ref.value
        if not picker or picker.closed then
          return
        end
        for item, idx in picker:iter() do
          if not item.dir then
            picker.list:view(idx)
            return
          end
        end
      end,
    },
    formatters = {
      file = {
        filename_only = opts.tree,
      },
    },
  })
end

```

#### Other files

- action.lua
- diagnositics.lua
- git.lua
- tree.lua
- watch.lua

#### finder

- lua/snacks/picker/source/explorer.lua -> M.explorer

- search   : `M.search()`    `/`
- findcher : `M.explorer()`  Globs the cwd recursively as Nodes (also diagnostics, git, e.t.c.), then display them in picker as Items

* これを finder = "explorer" のように指定するようだ。

#### matcher

いったん config でセットされているが、explorer.lua の setup() で上書きされている？
- config  : `matcher = { sort_empty = false, fuzzy = false },`
- setup() : `matcher = { on_match = function(matcher, item) ... end, on_done = function() ... end }` こちらになっているはず

わかりにくいが、Search 機能でのマッチングがこれだと思う。

#### filter

- config  : Nothing is set
- setup() : `transform = function(picker, filter) ... end`)
⭐️ ここでフィルター

#### searcher

- config  : Nothing is set
in picker default config, `search = 'serch_string'`. So it might be current search string.
And above `matcher` is the function for searching.


#### watcher

- config: `watch = true` this enables watcher.

でも、watch したあと ファイル更新を検知して zk.api.init や zk.api.list を呼んでくれるんだろうか？



### Config

- lua/snacks/picker/config/

以下のデフォルト設定を格納。

#### Defaults

lua/snacks/picker/config/defaults.lua

source 全体の共通な、デフォルトの config が網羅されている。

#### Highlight

lua/snacks/picker/config/highlights.lua

ハイライトを参照するショートカット名のリスト

#### Layout

lua/snacks/picker/config/layouts.lua

`:lua Snacks.picker.picker_layouts()` でリストアップ可能な、built-in レイアウトのデフォルト設定

#### Source

lua/snacks/picker/config/sources.lua

built-in Source のデフォルト設定。explorer もここに。

## picker 登録

WORKS:
```lua
-- Register picker
require('snacks.picker').pick(source_name, source_opts)
-- The `pick()` calls `require("snacks.picker.core.picker").new()` inside.
```
NOT WORKS or PARTIALLY WORKS:
```lua
require("snacks.picker")["zk"] = function(opts) M.open(opts) end -- NOT WORKS
Snacks["zk"] = function(opts) M.open(opts) end -- WORKS??? 存在しない、のエラー。open()後なら効く
require("snacks.picker").sources.zk = zk_source -- WORKS / 登録はできるが、Snacks.zk で呼び出せない / pikers list には表示される

```

## ソート

`lua/snacks/picker/sort.lua` が built-in の sorter `default` と `idx` の在り処。

> [!Caution]
> 残念ながら、explorer ではこれら全部まったく使えない。
> Tree:get() つまりその内部の Tree.walk() が読み込んだ順番そのままで表示される。
> sort オプションは一切考慮されない。

### Customize sorting in explorer

`Tree:get_zk()`, `Tree:walk_zk()`

`get_zk` が逐次ファイルを `walk_zk` で取得して処理していく。
`walk_zk` が処理している時点で、処理対象リストがすでに意図したソート順になっている必要がある。

-> 実現できた。`walk_zk` 内でソートした。

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

## node

内部的に保持している、ファイルやディレクトリの階層構造。parent, children, 展開状態(open) などを含めて管理。

Used by:
   - tree.lua
   - finder.lua
   - search.lua
   - sort.lua
(in `lua/snacks/zk` dir)

Class: Node
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
Sample (table): 辞書型
```lua
---@type table<string, snacks.picker.explorer.Node>
nodes = {
  -- directory (empty)
  ["notes"] = {
    children = {},
    dir = true,
    dir_status = "??",
    hidden = false,
    last = false,
    name = "notes",
    parent = { ["/path/to/parent"] = { ... } },
    path = "/Users/rio/Projects/terminal/test/notes",
    status = "??",
    type = "directory"
  },
  -- file
  ["zkeu83.md"] = {
    children = {},
    dir = false,
    hidden = false,
    last = true,
    name = "zkeu83.md",
    parent = { ["/path/to/parent"] = { ... } },
    path = "/Users/rio/Projects/terminal/test/zkeu83.md",
    severity = 1,
    status = " M",
    type = "file"
  },
  ...
}
```

## Item

picker が表示するフラット化されたリスト。並べ替え, ハイライト, アイコン表示 などを含む、UIに表示するためのデータ。
nodes とは異なり、＜path ではなく file がフルパス＞ などの違いがある。

Used by:
   - tree.lua
   - finder.lua
   - format.lua (snacks.picker.Item の方かも？)
(in `lua/snacks/zk` dir)


Class: Item
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
Sample (table): 辞書型
```lua
---@type table<string, snacks.picker.explorer.Item>
local items = {
  ["/path/to/file"] = {
    file = "/path/to/file",
    dir = true|false,
    open = true|false,
    dir_status = ???,
    text = "displayed text",
    parent = {},
    hidden = true|false,
    ignored = true|false,
    status = (not node.dir or not node.open or opts.git_status_open) and status or nil,
    last = true|false,,
    type = "directory"|"file",
    severity = ???, -- ノードの重要度？
    -- なぜか internal, sort, が無い
  },
  ...
}

```


## setup 時に設定済みのオプション値の取得

```lua
require("snacks.picker").sources.zk
```

## Tips


## その他

```lua
M.explorer = {
  finder = "explorer",
```
この finder は、lua/snacks/picker/source/*.lua の中で M.explorer のように設定されているものたち。

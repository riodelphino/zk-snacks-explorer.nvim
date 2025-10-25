# DEVELOPERS

Some notes for developers to help understanding:
  - `picker` and `Snacks.explorer` from `snacks.nvim`
  - `Snacks.zk` from `snacks-zk.nvim`.

## Structure

### zk (this repo)

The flow of calling picker:
| id  | function                       | role                                                 | via            | file                                       |
| --- | ------------------------------ | ---------------------------------------------------- | -------------- | ------------------------------------------ |
| 1   | Snacks.zk()                    | A shortcut entry point for the picker                | zk()           | (Snacks instanse)                          |
| 2   | Snacks.picker.zk(opts)         | The main entry point for the picker                  | zk(opts)       | (Snacks instanse) & lua/snacks/zk/init.lua |
| 3   | setmetatable                   | Returns `M.pick("zk", opts)` (Lazy load)             | setmetatable() | lua/snacks/picker/init.lua                 |
| 4   | Snacks.picker.pick("zk", opts) | Initialize and runs the picker                       | M.pick()       | lua/snacks/picker/init.lua                 |
| 5*  | Snacks.picker.sources.zk(opts) | Executes the actual `zk` picker logic (Tree, e.t.c.) | M.zk()         | lua/snacks/source/zk.lua                   |
`*` is the actual function excuted by `Snacks.zk(opts)`


#### Entry Point

- lua/snacks/zk/init.lua

Provides UI functions: `setup()`, `open()`, `reveal()`


### explorer (built-in)

#### Entry Point 1

- lua/snacks/source/explorer.lua

Snacks calls `M.setup()` function once automatically, when the source is loaded.

> [!Warning]
> Additional source like `zk-explorer`, this is not called automatically.
> Should call manually `require('snacks.picker.source.zk').setup()` in `config = function() ... end` option in `snacks-zk-explorer.nvim`.


#### Entry Point 2

- lua/snacks/explorer/init.lua

Provides UI functions: `setup()`, `open()`, `reveal()`

Though the config in `source.lua` is static, the one in `setup()` is dynamic. (e.g. Using existing `picker`)
That is the reason why the config is merged and force overwritten here.
```lua
---@param opts snacks.picker.zk.Config
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

- search : `M.search()`    `/`
- finder : `M.explorer()`  Globs the cwd recursively as Nodes (also diagnostics, git, e.t.c.), then display them in picker as Items

* The finder is specified like `{ finder = "explorer" }`.

#### matcher

The config is set here, but setup() in `explorer.lua` overwrites?
- config  : `matcher = { sort_empty = false, fuzzy = false },`
- setup() : `matcher = { on_match = function(matcher, item) ... end, on_done = function() ... end }` (This may overwrites above.)

This setting is used for matching in the Search function.

#### filter

- config  : Nothing is set
- setup() : `transform = function(picker, filter) ... end`)

filter here

#### searcher

- config  : Nothing is set
in picker default config, `search = 'serch_string'`. So it might be current search string.
And above `matcher` is the function for searching.


#### watcher

- config: `watch = true` this enables watcher.

Detect files & folders modification.



### Config

```bash
.
└── lua/snacks/picker/
    └── config/             # Includes below default config.
        ├── defaults.lua    # The common default config for all sources.
        ├── highlights.lua  # The shortcut name list for snacks Highlights.
        ├── layouts.lua     # The default config for built-in layouts.
        └── sources.lua     # The default config for built-in sources, including `explorer`.
```

## Register a picker

```lua
-- WORKS (Just add a source):
Snacks.picker.sources.zk = require("snacks.zk.source") -- Used at M.open() in `lua/snacks/zk/init.lua`
require('snacks.picker').source.zk = require('snacks.zk.source') -- This also works.

-- NOT WORKS:
require("snacks.picker")["zk"] = function(opts) M.open(opts) end -- NOT WORKS
Snacks["zk"] = function(opts) M.open(opts) end -- ERROR: not found

-- PARTIALLY WORKS:
require("snacks.picker").sources.zk = zk_source -- Registering OK and displayed in pikers list / But cannot call by `Snacks.zk`

-- Others:
require("snacks.picker.core.picker").new() -- NOT for registration
require('snacks.picker').pick("zk", zk_source) -- NOT for registration. Creates and opens a new picker.
-- *** WIERD BEHAVIOUR ***
-- It opens the picker imediately, which triggers M.open() in the zk module.
-- This causes unexpected behaviour where the picker opens and imediately closes.
```

## Get picker config

```lua
-- WORKS:
local zk_opts = require("snacks.picker").sources.zk -- The current config

-- PARTIALLY WORKS:
local zk_opts = require("snacks.zk.source") -- It's not current config but zk's default config

-- NOT WORKS
local zk_opts = Snacks.config.get({ source = "zk" }) -- WORKS when zk picker is opened. It returns `{}` if the picker not opened.
```

## ソート

`lua/snacks/picker/sort.lua`: Has built-in sorters `default` and `idx`

> [!Caution]
> Unfortunately, `Snacks.explorer` does not evaluate `sort` config.

### Customize sorting

`Tree:get()`, `Tree:walk()`
The items are already sorted as intended by walk.

`walk` recursively scans directries and find items, and `get` appends them into a table.
Since `picker.opts.sort` does not evaluated in `explorer`, the items shoud be already sorted as intended inside of `walk`. -> (implemented!)

### Sort

Basic

```lua
-- Basic sort
local source = {
   sort = { fields = { 'sort' } } -- Asc by item.sort
}
```
#### 2 ways for sorting

##### Use built-in sorter

```lua
-- by item.sort field (Asc)
sort = { fields = { 'sort' } }

-- by item.sort field (Asc explicitly)
sort = { fields = { 'sort:asc' } }

-- by item.sort field (Desc)
sort = { fields = { 'sort:desc' } }

-- by mutliple fields in item
sort = {
   fields = {
      "dir:desc",   -- by item.dir (Asc, dir first)
      "title",      -- by item.title (Asc)
      "idx"         -- by item.idx (Asc) = insertion order
   }
}

-- by the length of item.title string
sort = { 
   fields = { 
      "#title"
   }
}

-- by detailed table
sort = { 
   fields = {
      name = "title", -- by item.title field
      desc = true,    -- Descending
      len = true      -- Use length for sort (default: false)
   }
}

-- by combined list (detailed table and field name)
sort = { 
  fields = { 
    { name = "score", desc = true },  -- by item.score (Desc)
    "title"                           -- by item.title (Asc)
  }
}

-- Default sort
sort = { 
   fields = { 
      { name = "score", desc = true },  -- by score (Desc)
      "idx"                             -- by Insertion order (Asc)
   }
}
```
##### Use a sorter function

e.g.
```lua
sort = function(a, b)
   return a.name < b.name
end,
```


## node

An internally used hierarchical structure of files and directories by `Snacks.explorer` and `Snacks.zk`, including information such as parent/children/expand state.

Used by:
```bash
.
└── lua/snacks/zk/
    ├── tree.lua
    ├── finder.lua
    ├── search.lua
    └── sort.lua
```

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
Sample (dictionary-style table): 
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

A flattened list displayed by the picker. It includes sorting, highlighting, and icon display — data used for the UI.
Unlike nodes, it differs in aspects such as using `item.file` instead of `node.path` for full paths.

Used by:
```bash
.
└── lua/snacks/zk/
    ├── tree.lua
    ├── finder.lua
    └── format.lua  # or snacks.picker.Item?
```


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
Sample (dictionary-style table):
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
    severity = ???, -- ??? what's this?
    -- Somewhy, `internal` and `sort` are not listed here.
  },
  ...
}
```

## Tips

### opts.finder

Q. What does the finder "source_name" mean?
```lua
M.source_name = {
  finder = "source_name",
}
```
A. It reffers to the function with same name defined in `lua/snacks/picker/source/source_name.lua`:
```lua
function M.source_name(opts, ctx)
```

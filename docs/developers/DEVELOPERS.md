# DEVELOPERS

Some notes for developers to help understanding:
  - `picker` and `Snacks.explorer` from `snacks.nvim`
  - `Snacks.zk` from `snacks-zk.nvim`.

<!-- mtoc start -->
- [Structure](#structure)
   - [zk (this repo)](#zk-this-repo)
      - [Entry Point](#entry-point)
   - [explorer (built-in)](#explorer-built-in)
      - [Entry Point 1](#entry-point-1)
      - [Entry Point 2](#entry-point-2)
      - [Other files](#other-files)
      - [finder](#finder)
      - [matcher](#matcher)
      - [filter](#filter)
      - [searcher](#searcher)
      - [watcher](#watcher)
   - [Config](#config)
- [Register a picker](#register-a-picker)
   - [pickers](#pickers)
   - [Several ways to call pickers](#several-ways-to-call-pickers)
   - [Get picker config](#get-picker-config)
- [Sort](#sort)
   - [Customize sorting](#customize-sorting)
   - [Sort config](#sort-config)
- [Node](#node)
- [Item](#item)
- [picker](#picker)
- [Config](#config)
   - [confirm](#confirm)
- [Tips](#tips)
   - [Get picker](#get-picker)
   - [opts.finder](#opts-finder)
<!-- mtoc end -->

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

on_match : Main purpose is to add the parent directories to picker automatically.

#### filter

- config  : Nothing is set
- setup() : `transform = function(picker, filter) ... end`)

filter ??? transform ???

#### searcher

- config  : Nothing is set
in picker default config, `search = 'search_string'`. So it might be current search string.
And above `matcher` is the additional function suports searching.

`zk-explorer` does not use built-in command like `fd`, `rg`, `find` or seach filesystem.
It manually searches zk files from `M.note_cache` in `lua/snacks/zk/init.lua`, since `zk-explorer` has to search both the filename and the title.


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

require('snacks.zk').fetch_zk(Snacks.picker.zk()) -- WORKS but tricky
-- But it should be like this. fetch zk -> show picker

-- PARTIALLY WORKS:
require('snacks.picker').source.zk = require('snacks.zk.source') -- Registering OK and displayed in pikers list / But cannot call by `Snacks.zk`

-- NOT WORKS:
require("snacks.picker")["zk"] = function(opts) M.open(opts) end -- NOT WORKS
Snacks["zk"] = function(opts) M.open(opts) end -- ERROR: not found
Snacks.picker["zk"] = opts -- No meanings
require("snacks.picker.sources").zk = opts -- Error


-- Others:
require("snacks.picker.core.picker").new() -- NOT for registration
require("snacks.picker").pick("zk", opts) -- WORKS but opens picker imediately.
-- *** WIERD BEHAVIOUR ***
-- It opens the picker imediately, which triggers M.open() in the zk module.
-- This causes unexpected behaviour where the picker opens and imediately closes.


```
### pickers

FROM source doc:

```vim
:lua Snacks.picker.pickers(opts?)
```

List all available sources

```lua
{
  finder = "meta_pickers",
  format = "text",
  confirm = function(picker, item)
    picker:close()

    if item then
      vim.schedule(function()
        Snacks.picker(item.text)
      end)
    end
  end,
}
```
So, finaly pickers calls `Snacks.picker("zk")`


### Several ways to call pickers

:h snacks-picker-usage
```help
==============================================================================
2. Usage                                                 *snacks-picker-usage*

The best way to get started is to copy some of the example configs
<https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#-examples>
below.

>lua
    -- Show all pickers
    Snacks.picker()
    
    -- run files picker (all three are equivalent)
    Snacks.picker.files(opts)
    Snacks.picker.pick("files", opts)
    Snacks.picker.pick({source = "files", ...})
```

### Get picker config

```lua
-- WORKS:
local zk_opts = require("snacks.picker").sources.zk -- The current config

-- PARTIALLY WORKS:
local zk_opts = require("snacks.zk.source") -- It's not current config but zk's default config

-- NOT WORKS
local zk_opts = Snacks.config.get({ source = "zk" }) -- WORKS when zk picker is opened. It returns `{}` if the picker not opened.
```

## Sort

`opts.sort` accespts either function or config(table).
  - function: `@snacks.picker.sort`
  - config  : `@snacks.picker.sort.Config`

`lua/snacks/picker/sort.lua`: Has built-in sorter function `default` and `idx`.
`default` is a function which convert `@snacks.picker.sort.Field[]` fields into a sort function.

Below `M.sort()` function switches between fields and function.
lua/snacks/picker/config/init.lua:
```lua
---@param opts snacks.picker.Config
function M.sort(opts)
  local sort = opts.sort or require("snacks.picker.sort").default()
  sort = type(sort) == "table" and require("snacks.picker.sort").default(sort) or sort
  ---@cast sort snacks.picker.sort
  return sort
end
```

Usage:
```lua
local sort_function = require("snacks.picker.config").sort(opts)
table.sort(items|nodes, sort_function)
```

In most cases, below settings can cofigure the sorting.
  1. Set `item.sort` to a string that defines the sorting order. (item = `@snacks.picker.Item`)
  2. Then, set `sort = { fields = { 'sort' } }` in config.

`item.sort` should be set in `Tree.get()` within `M.zk()` in `zk.lua`.


> [!Caution]
> Unfortunately, `Snacks.explorer` does not evaluate `sort` config. --> But `zk-explorer` enables it.

### Customize sorting

`Tree:get()`, `Tree:walk()`
The items are already sorted as intended by walk.

`walk` recursively scans directries and find items, and `get` appends them into a table.
Since `picker.opts.sort` does not evaluated in `explorer`, the items shoud be already sorted as intended inside of `walk`. -> (implemented!)

### Sort config

Moved to [README.md #Sort](README.md#Sort)


## Node

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

## picker

The built-in picker functions are useful in some cases.

See `:h snacks.nvim-picker-snacks.picker.core.picker`

```lua
picker:action(actions)   -- Execute actions
picker:close()           -- Close picker
picker:count()
picker:current(opts)     -- Get current item
picker:current_win()     -- Get current win name
picker:cwd()             -- Get cwd
picker:dir()             -- Get current item's parent dir (or cwd)
picker:empty()           -- Check if the picker is empty
picker:filter()          -- Get the active filter
picker:find()
picker:focus(win, opts)  -- Focuses the given or configured window "input"|"list"|"preview"
picker:hist(forward)     -- Move the history cursor
picker:is_active()       -- Check if the finder or matcher is running
picker:is_focused()
picker:items()           -- Get all filtered items in the picker.
picker:iter()            -- Returns an iterator over the filtered items in the picker. Items will be in sorted order.
picker:norm(cb)          -- Execute the callback in normal mode
picker:on_current_tab()
picker:ref()
picker:resolve(item)      -- 
picker:selected(opts)     -- Get the selected items
picker:set_cwd(cwd)       -- Set cwd
picker:set_layout(layout) -- Set layout
picker:show_preview()     -- Show preview
picker:toggle(win, opts)  -- Toggle the given window and optionally focus
picker:word()             -- Get the word under the cursor or the current visual selection
```

## Config

### confirm

opts.confirm accepts string|string[]|function()

e.g.
```lua
confirm = "Choice"
confirm = {"Choice A", "Choice B"}
confirm = function(picker, item, action) ... end
```

opts.confirm:
```lua
M.man = {
  finder = "system_man",
  format = "man",
  preview = "man",
  confirm = function(picker, item, action)
    ---@cast action snacks.picker.jump.Action
    picker:close()
    if item then
      vim.schedule(function()
        local cmd = "Man " .. item.ref ---@type string
        if action.cmd == "vsplit" then
          cmd = "vert " .. cmd
        elseif action.cmd == "tab" then
          cmd = "tab " .. cmd
        end
        vim.cmd(cmd)
      end)
    end
  end,
}
```

confirm() function:
```lua
---@param prompt string
---@param fn fun()
function M.confirm(prompt, fn)
  Snacks.picker.select({ "No", "Yes" }, { prompt = prompt }, function(_, idx)
    if idx == 2 then
      fn()
    end
  end)
end
```
Example:
```lua
local fn = function() ... end
Snacks.picker.select(
  { "Title", "Title (-)", "Created", "Created (-)" },
  { prompt = prompt },
  function(item, idx)
    if idx ~= nil then
      fn()
    end
end)
```


## Tips

### Get picker
```lua
---@type snacks.Picker?
local picker = Snacks.picker.get({source = "zk"})[1]
```

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

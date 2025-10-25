# snacks-zk-explorer.nvim


Snacks source for zk, based on `Snacks.explorer`.

> [!Caution]
> This repository is experimental.
> Be careful to use it.
> Any PR is apprecieated.

## Features

- Tree style like `Snacks.explorer`
- Displays the title instead of the filename
- Shows Git and Diagnostics sign icons
- Search by the title
- Watch for files and directories (add/modify/rename/delete) 
- Queries
- User Config

(in future)
- Custom sorter
- Custom queries
- Custom actions

## Screen shots

:lua Snacks.zk()
![assets/images/screenshot_01.png](assets/images/screenshot_01.png)

Search 'a'
![assets/images/screenshot_02.png](assets/images/screenshot_02.png)


## Dependencies

- [folke/snacks.nvim](https://github.com/folke/snacks.nvim)
- [zk-org/zk-nvim](https://github.com/zk-org/zk-nvim)
- [zk-org/zk](https://github.com/zk-org/zk)


## Install

for lazy.nvim:
```lua
return {
  'riodelphino/snacks-zk.nvim',
  dependencies = { 'folke/snacks.nvim', 'zk-org/zk-nvim' },
  config = function()
    require('snacks.picker.source.zk').setup({}) -- Call setup once. Add to picker list, merge opts, e.t.c.
  end,
  keys = {
    { '<leader>ze', function() Snacks.zk() end, desc = 'Snacks.zk()' },
  }
}
```
~~* Automatically snacks calls `M.setup()` function in `lua/snacks/picker/source/zk.lua` on loading this picker.~~


## Config

```lua
require('snacks').setup({
  zk = {
    -- Set your custom config here
    -- See #default-config
  }
})
```

## Default Config

```lua
zk = {
  title = "Zk",
  finder = "zk", -- (fixed) Calls `require('snacks.picker.source.zk').zk()` function.
  reveal = true,
  supports_live = true,
  tree = true, -- (fixed) Always true on this picker and `false` not works
  watch = true,
  diagnostics = true,
  diagnostics_open = false,
  git_status = true,
  git_status_open = false,
  git_untracked = true,
  follow_file = true,
  focus = "list",
  auto_close = false,
  jump = { close = false },
  layout = { preset = "sidebar", preview = false },
  include = {}, -- (e.g. "*.jpg")
  exclude = {}, -- (e.g. "*.md")
  ignored = false,
  hidden = false,
  filter = {
    transform = nil, -- (fixed) *1
  },
  select = { "absPath", "filename", "title" }, -- Fields fetched by `zk.api.list`
  formatters = {
    file = {
      filename_only = nil, -- (fixed) *1
      filename_first = false,
      markdown_only = false, -- find only markdown files
    },
    severity = { pos = "right" },
  },
  format = nil, -- (fixed) *1
  matcher = {
    sort_empty = false,
    fuzzy = true,
    on_match = nil, -- (fixed) *1
    on_done = nil, -- (fixed) *1
  },
  sort = { fields = { "sort" } }, -- Need for search by `/`
  -- Sorters
  sorters = require("snacks.zk.sorters"),
  default_sorter = "title",
  -- Queries
  queries = require("snacks.zk.queries"),
  default_query = "all",
  query_postfix = ": ",
  -- Actions
  actions = require("snacks.zk.actions"),

  config = function(opts)
    return require("snacks.picker.source.zk").setup(opts)
  end,
  win = {
    list = {
      keys = {
        -- Supports explorer actions
        ["<BS>"] = "explorer_up",
        ["l"] = "confirm",
        ["h"] = "explorer_close", -- close directory
        ["a"] = "explorer_add",
        ["d"] = "explorer_del",
        ["r"] = "explorer_rename",
        ["c"] = "explorer_copy",
        ["m"] = "explorer_move",
        ["o"] = "explorer_open", -- open with system application
        ["P"] = "toggle_preview",
        ["y"] = { "explorer_yank", mode = { "n", "x" } },
        ["p"] = "explorer_paste",
        ["u"] = "explorer_update",
        ["<c-c>"] = "tcd",
        ["<leader>/"] = "picker_grep",
        ["<c-t>"] = "terminal", -- FIX: cause duplicated key error with `["<c-t>"] = "tab"`
        ["."] = "explorer_focus",
        ["I"] = "toggle_ignored",
        ["H"] = "toggle_hidden",
        ["Z"] = "explorer_close_all",
        ["]g"] = "explorer_git_next",
        ["[g"] = "explorer_git_prev",
        ["]d"] = "explorer_diagnostic_next",
        ["[d"] = "explorer_diagnostic_prev",
        ["]w"] = "explorer_warn_next",
        ["[w"] = "explorer_warn_prev",
        ["]e"] = "explorer_error_next",
        ["[e"] = "explorer_error_prev",
        -- zk actions
        ["z"] = "zk_change_query",
        ["Q"] = "zk_reset_query",
        -- Unset default keymaps "z*" -- TODO: To avoid waiting next key after 'z'. Any other solutions?
        ["zb"] = false, -- "list_scroll_bottom",
        ["zt"] = false, -- "list_scroll_top",
        ["zz"] = false, -- "list_scroll_center",
        -- See lua/snacks/picker/config/defaults.lua
      },
    },
  },
}
-- *1 : Always dynamically overwritten by `setup()` in `zk.lua`
-- *2 : Setting a table in sort like `sort = { fields = { "sort" } }` is completely skipped by `explorer` and `zk`
```

> [!Note]
> `Tree` view is fixed for zk picker, since it is the purpose for this repo. So `{ tree = false }` not works.


## Usage

Open:
```lua
Snacks.zk() -- Shortcut for Snacks.picker.zk()
Snacks.picker.zk()
require('snacks.zk').open() -- Call open() function directry
```
Open with custom config:
```lua
---@type (snacks.picker.zk.Config | {})?
local opts = {} -- Set your custom config here / See #default-config
Snacks.zk(opts)
Snacks.picker.zk(opts)
require('snacks.zk').open(opts)
```

Open in another layout:
```lua
Snacks.zk({ layout = "default" }) -- bottom|default|dropdown|ivy|ivy_split|left|right|select|sidebar|telescope|top|vertical|vscode
Snacks.zk({ layout = "left" }) -- 'left' (snacks-zk.nvim's default)
```

> [!Warning]
> `layout = "telescope"` breaks the order for `reverse = true` config.


## Sorters

Add custom sorter `created`:
```lua
select = { "title", "absPath", "filename", "created"},
sorters = {
  created = function(a, b) -- FIX: error
    local notes = require("snacks.zk").notes_cache
    local an = notes[a.path] or nil
    local bn = notes[b.path] or nil
    local ac = an and an.created
    local bc = bn and bn.created
    a_has_created = (an.created ~= nil)
    b_has_created = (bn.created ~= nil)
    if a_has_created ~= b_has_created then
      return a_has_created < b_has_created
    end
    if a_has_created and b_has_created then
      return a.created < b.created
    end
    return a.filename < b.filename
  end,
}
```
Use custom sorter:
```lua
default_sorter = "created"
```


## Queries

Keymaps (in the file tree):
   - `z` key shows a list of queries.
   - `Q` key reset the current query(=All).

Queries in lua:
```lua
-- Change query
require('snacks.zk.actions').actions.zk_change_query()
-- Reset query
require('snacks.zk.actions').actions.zk_reset_query()
```

Available queries:
  - All (default)
  - Created
  - Created after
  - Created before
  - Modified
  - Modified after
  - Modified before
  - Match (exact)
  - Match (full-text)
  - Match (regular expression)
  - Mention
  - Mentioned by
  - Link to
  - Link to (recursive)
  - Linked by (recursive)
  - Linked by
  - Filmsy
  - Orphans
  - Related
  - Tag

### Add Custom Queries

Add cusotm query `todo`:
```lua
queries = {
  todo = {
    desc = "todo",
    input = function(__, __, cb)
      cb({ desc = "Todo", query = { tags = { "todo" } } })
    end,
  },
},
```
Use custom query `todo`:
  `z` key in `zk-explorer`, then select `todo`.

## Actions

### Add Custom Actions

Not implemented yet...

```lua
-- DEBUG: Should be merged with require("snacks.actions").actions table, not in the root.
actions = {
  zk_add_new = function()
    ...
  end,
},
```

Use Custom Actions:
```lua
win = {
  list = {
    keys = {
      ["A"] = "zk_add_new",
    },
  },
},
```

## Issues

- Warning when opening zk picker: `["<c-t>"] = "terminal"` and `["<c-t>"] = "tab"`.
- The focus is lost when query select.ui is canceled.


## TODO

- [ ] Add action for zk.api.new()
- [ ] Supports custom actions for zk?
- [ ] Supports custom queries
- [ ] Supports custom sorter (`M.change_sorter()` is already implemented in `init.lua`)


## Related

- [folke/snacks.nvim](https://github.com/folke/snacks.nvim)
- [zk-org/neo-tree-zk.nvim](https://github.com/zk-org/neo-tree-zk.nvim)
- [zk-org/zk-nvim](https://github.com/zk-org/zk-nvim)
- [zk-org/zk](https://github.com/zk-org/zk)


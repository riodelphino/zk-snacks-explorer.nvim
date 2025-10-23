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
```lua:snacks-zk.lua
return {
  'riodelphino/snacks-zk.nvim',
  dependencies = { 'folke/snacks.nvim', 'zk-org/zk-nvim' },
  keys = {
    { '<leader>ze', function() Snacks.zk() end, desc = 'Snacks.zk()' },
  }
}
```
* Automatically snacks calls `M.setup()` function in `lua/snacks/picker/source/zk.lua` on loading this picker.


## Config

It has no options yet.


## Usage

Open:
```lua
Snacks.zk() -- Shortcut for Snacks.picker.zk()
Snacks.picker.zk()
require('snacks.zk').open() -- Call open() function directry
```
Open with custom config:
```lua
---@type (snacks.picker.explorer.Config | {})?
local opts = {} -- Set your custom config here / See defaults at `lua/snacks/zk/source.lua`
Snacks.zk(opts)
Snacks.picker.zk(opts)
require('snacks.zk').open(opts)
```

Open in another layout:
```lua
Snacks.zk({ layout = "default" }) -- bottom|default|dropdown|ivy|ivy_split|left|right|select|sidebar|telescope|top|vertical|vscode
Snacks.zk({ layout = "left" }) -- 'left' (snacks-zk.nvim's default)
-- 'telescope' breaks the order for 'reverse = true' config.
```


> [!Note]
> `Tree` view is fixed for zk picker, since it is the purpose for this repo. So `{ tree = false }` not works.


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


## Issues

- Warning when opening zk picker: `["<c-t>"] = "terminal"` and `["<c-t>"] = "tab"`.
- The focus is lost when query select.ui is canceled.


## TODO

- [ ] Provide options for users
- [ ] Add action for zk.api.new()
- [ ] Supports custom actions for zk?
- [ ] Supports custom queries


## Related

- [folke/snacks.nvim](https://github.com/folke/snacks.nvim)

- [zk-org/neo-tree-zk.nvim](https://github.com/zk-org/neo-tree-zk.nvim)
- [zk-org/zk-nvim](https://github.com/zk-org/zk-nvim)
- [zk-org/zk](https://github.com/zk-org/zk)


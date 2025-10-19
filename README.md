# snacks-zk.nvim


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

## Screen shots

:lua Snacks.zk()
![assets/images/screenshot_01.png](assets/images/screenshot_01.png)

Search 'a'
![assets/images/screenshot_02.png](assets/images/screenshot_02.png)

## Issues

- It does not provide any `queries` or `actions` like [neo-tree-zk.nvim](https://github.com/zk-org/neo-tree-zk.nvim) does.


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
---@type (snacks.picker.explorer.Config | {})?
local opts = {} -- Set your custom config here / default is in `lua/snacks/zk/source.lua`
Snacks.zk(opts)
Snacks.picker.zk(opts)
require('snacks.zk').open(opts)
```

## TODO

- [ ] Provide options for users
- [ ] Provide actions ?
- [ ] Provide queries(filters) ?


## Related

- [folke/snacks.nvim](https://github.com/folke/snacks.nvim)
- [zk-org/neo-tree-zk.nvim](https://github.com/zk-org/neo-tree-zk.nvim)
- [zk-org/zk-nvim](https://github.com/zk-org/zk-nvim)
- [zk-org/zk](https://github.com/zk-org/zk)


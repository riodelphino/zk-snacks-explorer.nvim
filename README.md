# snacks-zk.nvim


Snacks source for zk, based on `Snacks.explorer`.

> [!Caution]
> This repository is experimental.
> Be careful to use it.
> Any PR is apprecieated.

## Features

- Snacks.explorer style
- Display the title instead of the filename


## Known issues

- When zk picker is opened at the first time, it is automatically closed.
- `Searching by title` does not work.
- It does not provide any `queries` or `actions` like [neo-tree-zk.nvim](https://github.com/zk-org/neo-tree-zk.nvim) does.


## Install

for lazy.nvim:
```lua:snacks-zk.lua
return {
  'riodelphino/snacks-zk.nvim',
  dependencies = { 'folke/snacks.nvim', 'zk-org/zk-nvim' },
  config = function()
    require('snacks.zk').setup()
  end,
  keys = {
    { '<leader>ze', function() Snacks.zk() end, desc = 'Snacks.zk()' },
  }
}
```

## Config

It has no options yet.


## Usage

Open zk picker:
```lua
local opts = {} ---@type snacks.picker.explorer.Config|{}
Snacks.zk(opts)
Snacks.picker.zk(opts)
require('snacks.zk').open(opts)
```
Open zk picker with revealing:
```lua
local opts ---@type {file?:string, buf?:number}
opts = { buf = 0 } -- or
opts = { file = "path/to/file" }
require('snacks.zk').reveal(opts) -- NOT WORKS for now, but above codes reveal current file somehow.
```


## TODO

- [x] Enable sorting
- [ ] Not to close at the first loading
- [ ] Enable searching by title
- [ ] Provide options for users
- [ ] Provide actions ?
- [ ] Provide queries ?


## Related

- [zk-org/neo-tree-zk.nvim](https://github.com/zk-org/neo-tree-zk.nvim)
- [zk-org/zk-nvim](https://github.com/zk-org/zk-nvim)
- [zk-org/zk](https://github.com/zk-org/zk)


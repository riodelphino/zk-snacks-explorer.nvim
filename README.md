# snacks-zk.nvim


Snacks source for zk, based on `Snacks.explorer`.

> [!Caution]
> This repository is experimental.
> Be careful to use it.
> Any PR is apprecieated.


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
}
```

## Config

It has no options yet.


## Keymaps

`snacks-zk.nvim` keymaps should be set by `snacks.nvim`

for lazy.nvim:
```lua
return {
  'folke/snacks.nvim',
  ...
  keys = {
    ...
    { '<leader>w', function() Snacks.zk() end, desc = 'Snacks.zk()' },
  },
}
```

## Usage

Open zk picker:
```lua

---@type snacks.picker.explorer.Config|{}
local opts = {} -- set your options

Snacks.zk(opts)
Snacks.picker.zk(opts)
require('snacks.zk').open(opts)
```

Open zk picker with revealing:
```lua
---@type {file?:string, buf?:number}
local opts = { buf = 0 } -- or
local opts = { file = "path/to/file" }
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


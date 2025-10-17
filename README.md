# snacks-zk.nvim


Snacks source for zk, based on `Snacks.explorer`.


Sorting and searching do not work for now.

## Install

for lazy.nvim:
```lua:snacks-zk.lua
return {
   'riodelphino/snacks-zk.nvim',
   dependencies = { 'zk-org/zk-nvim', 'folke/snacks.nvim' },
   config = function()
      require('snacks.zk').setup()
   end,
}
```

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

```lua
-- Open zk source
Snacks.zk()
Snacks.picker.zk()
require('snacks.zk').open()

-- Reveal?
require('snacks.zk').reveal() -- NOT WORKS for now
```


## TODO

- [ ] Enable sorting
- [ ] Enable `/` searching by title


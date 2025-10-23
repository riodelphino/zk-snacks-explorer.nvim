---@class snacks.picker.zk.Config : snacks.picker.explorer.Config
---@field sorters table?

---@type snacks.picker.zk.Config
local source = {
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
  sorters = {
    ---@param a snacks.picker.explorer.Node
    ---@param b snacks.picker.explorer.Node
    ---@return boolean
    default = function(a, b) -- *2
      local notes = require("snacks.zk").notes_cache
      local an = notes[a.path] or nil
      local bn = notes[b.path] or nil
      local at = an and an.title
      local bt = bn and bn.title
      local a_has_title = (at ~= nil)
      local b_has_title = (bt ~= nil)
      local a_is_dot = (a.name:sub(1, 1) == ".")
      local b_is_dot = (b.name:sub(1, 1) == ".")
      if a.dir ~= b.dir then
        return a.dir
      end
      if a_is_dot ~= b_is_dot then
        return not a_is_dot
      end
      if a_has_title ~= b_has_title then
        return a_has_title
      end
      if a_has_title and b_has_title then
        return at < bt
      end
      return a.name < b.name
    end,
  },
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

return source

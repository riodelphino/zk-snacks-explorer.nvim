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
  select = { "absPath", "filename", "title", "metadata", "modified", "created" }, -- Fields fetched by `zk.api.list`
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

  -- Sort
  -- sort = { fields = {} }, -- OK
  sort = { fields = { "sort" } }, -- OK
  -- sort = { fields = { "!zk" } }, -- OK (Caution: `*.md` files without YAML or title also have zk field)
  -- sort = { fields = { "dir", "hidden:desc", "!zk.title", "zk.title", "name" } }, -- OK (Almost same with `fields = { "sort" }`)
  -- sort = { fields = { "dir", "hidden:desc", "zk.metadata.created" } }, -- OK
  -- sort = function(a, b) -- OK
  --   return (a.title or a.path or a.file) < (b.title or b.path or b.file)
  -- end,

  sorters = require("snacks.zk.sorters"),
  -- Query
  -- query = "all", -- DEBUG: If set string, the query should have static `query` field. Error if has `input` field as function.
  query = { desc = "all", query = {} },
  queries = require("snacks.zk.queries"),
  query_postfix = ": ",
  -- Actions
  actions = require("snacks.zk.actions"),

  -- config = function(opts) -- This functions is not evaluated.
  --   return require("snacks.picker.source.zk").setup(opts)
  -- end,
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
        ["s"] = "zk_change_sort",
        ["S"] = "zk_reset_sort",
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

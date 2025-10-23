local source = {
  title = "Zk",
  finder = "zk", -- calls `require('snacks.picker.source.zk').zk()` function.
  reveal = true,
  supports_live = true,
  tree = true, -- Always true on this picker (`false` not works)
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
    transform = nil, -- Always overwritten by `setup()` in `zk.lua`
  },
  formatters = {
    file = {
      filename_only = true, -- In the zk `setup()`, `filename_only` is overridden by `opts.tree`.
      filename_first = false,
      markdown_only = false, -- find only markdown files
    },
    severity = { pos = "right" },
  },
  format = nil, -- Always overwritten by `setup()` in `zk.lua`
  matcher = {
    sort_empty = false,
    fuzzy = true,
    -- on_match = nil, -- Always overwritten by `setup()` in `zk.lua`
    -- on_done = nil, -- Always overwritten by `setup()` in `zk.lua`
  },
  sort = { fields = { "sort" } }, -- `sort` is skipped completely in `explorer` or `zk`
  config = function(opts)
    return require("snacks.picker.source.zk").setup(opts)
  end,
  win = {
    list = {
      keys = {
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
        -- zk
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

return source

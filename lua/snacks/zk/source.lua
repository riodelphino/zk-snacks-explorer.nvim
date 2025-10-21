local zk_format = require("snacks.zk.format") ---@type table

local source = {
  -- finder = zk_finder,
  finder = "zk", -- calls the `zk` function from `require('snacks.picker.source.zk')`.
  reveal = true,
  supports_live = true,
  tree = true, -- keep true on this picker (`false` not works)
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
  formatters = {
    file = {
      filename_only = true, -- In the zk `setup()`, `filename_only` is overridden by `opts.tree`.
      filename_first = false,
      markdown_only = false, -- find only markdown files
    },
    severity = { pos = "right" },
  },
  format = zk_format.zk_file,
  matcher = { sort_empty = false, fuzzy = true },
  -- sort:
  --  NOT WORKS in `explorer`. This option is skipped.
  --  Since `Tree:get()` generate a node and add it into UI one by one, sorting should be completed inside of the `walk_zk()`
  sort = { fields = { "sort" } },
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
        ["<c-t>"] = "terminal",
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
      },
    },
  },
}

return source

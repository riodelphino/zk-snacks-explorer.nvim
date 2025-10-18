local zk_finder = require("snacks.zk.finder")
local zk_format = require("snacks.zk.format")

local source = {
  finder = zk_finder,
  reveal = true,
  supports_live = true,
  tree = true,
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
  include = {}, -- WORKS
  exclude = {}, -- WORKS : "*.md" style
  ignored = false, -- WORKS
  hidden = false, -- WORKS
  formatters = {
    file = {
      filename_only = true, -- NOTE: explorer の setup では `filename_only = opts.tree,` のように filename_only を左右し上書きしている。影響がなぜかある
      filename_first = false,
      markdown_only = true,
    },
    severity = { pos = "right" },
  },
  format = zk_format.zk_file,
  matcher = { sort_empty = false, fuzzy = false },
  sort = { fields = { "sort" } }, -- NOTE: NOT WORKS: explorer skips this opt.
  --`Tree:get()` generate a node and add it into UI one by one. Sorting should be completed inside of the `walk_zk()`

  config = function(opts)
    -- return require("snacks.picker.source.zk").setup(opts) -- DEBUG: explorer is enough (Really??)
    return require("snacks.picker.source.explorer").setup(opts)
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
      },
    },
  },
}

return source

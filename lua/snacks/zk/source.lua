local zk_format = require("snacks.zk.format")
local zk_finder = require("snacks.zk.finder")

local source = {
   finder = zk_finder,
   reveal = true,
   supports_live = true,
   tree = false,
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
   formatters = {
      zk_file = { filename_only = true }, -- DEBUG: file に戻さなくて大丈夫？
      severity = { pos = "right" },
   },
   format = zk_format.zk_file,
   matcher = { sort_empty = false, fuzzy = false },
   sort = { fields = { "sort" } }, -- DEBUG: explorer Tree:get() が内部で逐次ファイルを読み込みながらノードを生成表示するので、意味なし

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

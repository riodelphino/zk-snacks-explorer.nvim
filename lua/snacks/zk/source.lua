---@class snacks.picker.explorer.Config: snacks.picker.files.Config|{}
---@field follow_file? boolean follow the file from the current buffer
---@field tree? boolean show the file tree (default: true)
---@field git_status? boolean show git status (default: true)
---@field git_status_open? boolean show recursive git status for open directories
---@field git_untracked? boolean needed to show untracked git status
---@field diagnostics? boolean show diagnostics
---@field diagnostics_open? boolean show recursive diagnostics for open directories
---@field watch? boolean watch for file changes
---@field exclude? string[] exclude glob patterns
---@field include? string[] include glob patterns. These take precedence over `exclude`, `ignored` and `hidden`
local source = {
   -- finder = "zk", -- DEBUG: finder は explorer でよくね？
   finder = "explorer",
   sort = { fields = { "sort" } },
   supports_live = true,
   tree = false,
   watch = true,
   diagnostics = true,
   diagnostics_open = false,
   git_status = false,
   git_status_open = false,
   git_untracked = true,
   follow_file = true,
   focus = "list",
   auto_close = false,
   jump = { close = false },
   layout = { preset = "sidebar", preview = false },
   -- to show the explorer to the right, add the below to
   -- your config under `opts.picker.sources.explorer`
   -- layout = { layout = { position = "right" } },
   formatters = {
      zk_file = { filename_only = true }, -- DEBUG: これは zk_file を呼び出してはくれないのか？
      severity = { pos = "right" },
   },
   -- format = "zk_file", -- DEBUG: どうだ！？
   -- format = require("snacks.picker.format").zk_file, -- DEBUG: どうだ！？
   -- format = function(item, picker) -- DEBUG: 遅延させないとだめみたい。まだマージされて無いから？ これでもだめ。
   --    return require("snacks.picker.format").zk_file(item, picker)
   -- end,
   --
   format = require("snacks.zk.format").zk_file, -- WORKS! 荒業すぎる
   matcher = { sort_empty = false, fuzzy = false },
   config = function(opts)
      -- return require("snacks.picker.source.zk").setup(opts) -- DEBUG: lua/snacks/picker/source/zk.lua を改名して仮削除 いらないんじゃね？ってことで
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

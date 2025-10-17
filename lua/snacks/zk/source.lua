local zk_format = require("snacks.zk.format")
local zk_finder = require("snacks.zk.finder")
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
   -- finder =
   -- finder = "explorer", -- "zk", -- "explorer" is enough
   finder = zk_finder, -- DEBUG: 動く？
   -- finder = "zk_finder", -- DEBUG: 動く？
   -- finder = function(opts, ctx)
   --    return Snacks.picker.sources.explorer.zk_finder(opts, ctx)
   -- end,
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
   -- format = function(item, picker)
   --    return require("snacks.picker.format").zk_file(item, picker)
   -- end,
   format = zk_format.zk_file, -- 遅延しなくてもこれで大丈夫じゃん
   matcher = { sort_empty = false, fuzzy = false },
   -- sort = { fields = { "sort" } }, -- item.sort の文字列でソートする、の意
   -- sort = { -- DEBUG: NOT WORKS
   --    fields = {
   --       -- "dir:desc", -- item.dir で降順（ディレクトリが先）
   --       "title", -- item.title で昇順
   --       -- "idx", -- 同じなら item.idx（追加順）}
   --    },
   -- },
   -- sort = function(a, b)
   --    print(a.file .. " dir: " .. tostring(a.dir)) -- DEBUG: 呼ばれてない
   --    return a.title < b.title
   -- end,
   -- sort = { fields = { "sort" } }, -- DEBUG: 効かない ていうか、2回目の描画ではデフォルト設定が上書きされてる
   -- sort = { fields = { "title" } }, -- DEBUG: 読み込まれる？が、効かない sort.lua の defaults も呼ばれるがその中の return の f(a,b) が呼ばれない
   -- sort = function(a, b) -- DEBUG: 呼ばれん
   --    print(vim.inspect(a))
   --    return a.file < b.file
   -- end,
   -- sort = { fields = { "file" } }, -- DEBUG:
   -- sorter = function(a, b) -- DEBUG : こんなの効くのかよ？ ChatGPTさんよー やっぱ効かねぇよー ウソ書くなよー
   --    print("sorter is called")
   --    return a.title or a.file < b.title or b.file
   -- end,
   sort = { fields = { "sort" } }, -- DEBUG: explorer の原点に戻ってみる

   config = function(opts)
      -- return require("snacks.picker.source.zk").setup(opts) -- DEBUG: explorer is enough
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

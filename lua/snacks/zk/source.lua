---@type snacks.picker.zk.Config
local source = {
  enabled = function() -- Enabled if zk directory
    local util = require("snacks.zk.util")
    local notebook_path = util.fs.get_notebook_path()
    return notebook_path ~= nil
  end,
  title = "Zk",
  finder = "zk", -- Same with `finder = function(opts, ctx) return require('snacks.picker.source.zk').zk(opts, ctx) end`
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
      ---@type snacks.picker.zk.formatters.file.zk.Config
      zk = {
        filename = require("snacks.zk.format").filename,
        transform = {
          ---@type snacks.picker.zk.formatters.file.zk.transform.Icon
          icon = function(item, note, icon, hl)
            -- A file has title
            if not item.dir and not item.hidden and note and (note.title or note.metadata and note.metadata.title) then
              icon = "󰎞"
              hl = "SnacksPickerZkNoteIcon"
            end
            -- A dir includes zk files
            if item.dir and note then
              icon = "󰉗"
            end
            return icon, hl
          end,
          ---@type snacks.picker.zk.formatters.file.zk.transform.Text
          text = function(item, note, base, base_hl, dir_hl)
            -- A dir includes zk files
            if item.dir and not item.hidden and note then
              dir_hl = "SnacksPickerZkDirText"
              base_hl = "SnacksPickerZkDirText"
            end
            -- A file not zk
            if not item.dir and not note then
              base_hl = "SnacksPickerDimmed"
            end
            -- Use title if exists
            base = not item.dir and note and (note.title or note.metadata and note.metadata.title) or base
            return base, base_hl, dir_hl
          end,
        },
      },
    },
    severity = { pos = "right" },
  },
  format = require("snacks.zk.format").file,
  matcher = {
    sort_empty = false,
    fuzzy = true,
    on_match = nil, -- (fixed) *1
    on_done = nil, -- (fixed) *1
  },
  -- sort = { fields = {} }, -- OK
  sort = { fields = { "sort" } }, -- OK
  -- sort = { fields = { "!zk" } }, -- OK (Caution: `*.md` files without YAML or title also have zk field)
  -- sort = { fields = { "dir", "hidden:desc", "!zk.title", "zk.title", "name" } }, -- OK (Almost same with `fields = { "sort" }`)
  -- sort = { fields = { "dir", "hidden:desc", "zk.metadata.created" } }, -- OK
  -- sort = function(a, b) -- OK
  --   return (a.title or a.path or a.file) < (b.title or b.path or b.file)
  -- end,
  sorters = require("snacks.zk.sorters"),
  query = { desc = "all", query = {}, include_none_zk = true },
  queries = require("snacks.zk.queries"),
  query_postfix = ": ",
  actions = require("snacks.zk.actions"),
  highlights = {
    SnacksPickerZkNoteIcon = { fg = "#E8AB53" },
    SnacksPickerZkNoteText = { link = "SnacksPickerList" },
    SnacksPickerZkDirIcon = { link = "SnacksPickerDirectory" },
    SnacksPickerZkDirText = { link = "SnacksPickerDirectory" },
  },
  config = function(opts) end,
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
        -- ["<c-t>"] = "terminal", -- TODO: Duplicated key error with `["<c-t>"] = "tab"`
        ["."] = "explorer_focus",
        ["I"] = "toggle_ignored",
        ["H"] = "toggle_hidden",
        -- ["Z"] = "explorer_close_all",
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
        ["Z"] = "zk_reset_query",
        ["s"] = "zk_change_sort",
        ["S"] = "zk_reset_sort",
        ["i"] = "zk_show_item_info",
        -- Unset default keymaps "z*" -- Unset useless keys to avoid waiting next key after 'z'.
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

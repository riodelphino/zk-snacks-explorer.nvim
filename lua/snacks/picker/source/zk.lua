---@diagnostic disable: await-in-sync

local zk = require("snacks.zk")
local util = require("snacks.zk.util")

local Tree = require("snacks.zk.tree")

local M = {}

---@type table<snacks.Picker, snacks.picker.explorer.State>
M._state = setmetatable({}, { __mode = "k" })
local uv = vim.uv or vim.loop

local function norm(path)
  return svim.fs.normalize(path)
end

---@class snacks.picker.explorer.State
---@field on_find? fun()?
local State = {}
State.__index = State
---@param picker snacks.Picker
function State.new(picker)
  local self = setmetatable({}, State)
  local actions = zk.opts.actions

  local opts = picker.opts --[[@as snacks.picker.zk.Config]]
  local r = picker:ref()
  local function ref()
    local v = r.value
    return v and not v.closed and v or nil
  end

  Tree:refresh(picker:cwd())

  local buf = vim.api.nvim_win_get_buf(picker.main)
  local buf_file = svim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  if uv.fs_stat(buf_file) then
    Tree:open(buf_file)
  end

  if opts.watch then
    local on_close = picker.opts.on_close
    picker.opts.on_close = function(p)
      require("snacks.zk.watch").abort()
      if on_close then
        on_close(p)
      end
    end
  end

  picker.list.win:on("BufWritePost", function(_, ev)
    local p = ref()
    if p then
      Tree:refresh(ev.file)
      actions.update(p)
    end
  end)

  picker.list.win:on("DirChanged", function(_, ev)
    local p = ref()
    if p then
      p:set_cwd(svim.fs.normalize(ev.file))
      p:find()
    end
  end)

  if opts.diagnostics then
    local dirty = false
    local diag_update = Snacks.util.debounce(function()
      dirty = false
      local p = ref()
      if p then
        if require("snacks.explorer.diagnostics").update(p:cwd()) then
          p.list:set_target()
          p:find()
        end
      end
    end, { ms = 200 })
    picker.list.win:on({ "InsertLeave", "DiagnosticChanged" }, function(_, ev)
      dirty = dirty or ev.event == "DiagnosticChanged"
      if vim.fn.mode() == "n" and dirty then
        diag_update()
      end
    end)
  end

  -- schedule initial follow
  if opts.follow_file then
    picker.list.win:on({ "WinEnter", "BufEnter" }, function(_, ev)
      vim.schedule(function()
        if ev.buf ~= vim.api.nvim_get_current_buf() then
          return
        end
        local p = ref()
        if not p or p:is_focused() or not p:on_current_tab() or p.closed then
          return
        end
        local win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_config(win).relative ~= "" then
          return
        end
        local file = vim.api.nvim_buf_get_name(ev.buf)
        local item = p:current()
        if item and item.file == norm(file) then
          return
        end
        actions.update(p, { target = file })
      end)
    end)
    self.on_find = function()
      local p = ref()
      if p and buf_file then
        actions.update(p, { target = buf_file })
      end
    end
  end
  return self
end

---@param ctx snacks.picker.finder.ctx
function State:setup(ctx)
  local opts = ctx.picker.opts --[[@as snacks.picker.zk.Config]]
  if opts.watch then
    require("snacks.zk.watch").watch(ctx.filter.cwd)
  end
  return not ctx.filter:is_empty()
end

---@param opts snacks.picker.zk.Config
function M.setup(opts)
  print("lua/snacks/picker/source/zk.lua M.setup()") -- DEBUG:

  local searching = false
  local ref ---@type snacks.Picker.ref

  -- Merge all static config
  local default_opts = require("snacks.zk.source")
  local picker_opts = Snacks.config.get("picker", {})
  local user_opts = picker_opts.sources and picker_opts.sources.zk or {}
  opts = Snacks.config.merge(default_opts, user_opts, opts)

  -- Merge dynamic config
  opts = Snacks.config.merge(opts, {
    actions = {
      confirm = opts.actions.actions.confirm,
    },
    filter = {
      --- Trigger finder when pattern toggles between empty / non-empty
      ---@param picker snacks.Picker
      ---@param filter snacks.picker.Filter
      transform = function(picker, filter)
        ref = picker:ref()
        local s = not filter:is_empty()
        if searching ~= s then
          searching = s
          filter.meta.searching = searching
          return true
        end
      end,
    },
    matcher = {
      --- Add parent dirs to matching items
      ---@param matcher snacks.picker.Matcher
      ---@param item snacks.picker.explorer.Item
      on_match = function(matcher, item)
        if not searching then
          return
        end
        local picker = ref.value
        if picker and item.score > 0 then
          local parent = item.parent
          while parent do
            if parent.score == 0 or parent.match_tick ~= matcher.tick then
              parent.score = 1
              parent.match_tick = matcher.tick
              parent.match_topk = nil
              parent.dir = true -- Ensure dir
              parent.sort = util.sort.get_sort_key(parent)
              picker.list:add(parent)
            else
              break
            end
            parent = parent.parent
          end
        end
      end,
      on_done = function()
        if not searching then
          return
        end
        local picker = ref.value
        if not picker or picker.closed then
          return
        end
        for item, idx in picker:iter() do
          if not item.dir then
            picker.list:view(idx)
            return
          end
        end
      end,
    },
    formatters = {
      file = {
        filename_only = opts.tree,
      },
    },
    default_query = opts.query, -- Save it as default
    default_sort = opts.sort, -- Save it as default
  })

  zk.opts = opts -- keep it in `snacks.zk` module for easy use.
  zk.notebook_path = require("zk.util").notebook_root(require("zk.util").resolve_notebook_path(0) or vim.fn.getcwd()) -- TODO: Should be opts.notebook_path?

  local enabled = opts.enabled == true or type(opts.enabled) == "function" and opts.enabled() == true
  if enabled then -- Register if enabled
    require("snacks.picker").sources.zk = opts -- As a source
    Snacks.picker["zk"] = function(runtime_opts) -- As `Snacks.picker.zk()`
      local merged_opts = Snacks.config.merge(opts, runtime_opts or {})
      return Snacks.picker.pick("zk", merged_opts)
    end
    util.hl.set_highlights(opts.highlights or {})
  end
  return opts
end

---@param picker snacks.Picker
function M.get_state(picker)
  if not M._state[picker] then
    M._state[picker] = State.new(picker)
  end
  return M._state[picker]
end

---@param opts snacks.picker.zk.Config
---@type snacks.picker.finder
function M.zk(opts, ctx)
  local state = M.get_state(ctx.picker)

  if opts.git_status then
    require("snacks.explorer.git").update(ctx.filter.cwd, {
      untracked = opts.git_untracked,
      on_update = function()
        if ctx.picker.closed then
          return
        end
        ctx.picker.list:set_target()
        ctx.picker:find()
      end,
    })
  end

  if opts.diagnostics then
    require("snacks.explorer.diagnostics").update(ctx.filter.cwd)
  end

  return function(cb)
    if state.on_find then
      ctx.picker.matcher.task:on("done", vim.schedule_wrap(state.on_find))
      state.on_find = nil
    end

    -- Start watcher
    if state:setup(ctx) then
      return M.search(opts, ctx)(cb) -- Switch to search mode when filter enabled
    end

    local items = {} ---@type table<string, snacks.picker.explorer.Item>
    local top = Tree:find(ctx.filter.cwd)
    local root = {
      file = ctx.filter.cwd,
      dir = true,
      open = true,
      hidden = false,
      internal = true,
      sort = "",
      text = ctx.filter.cwd,
    }

    Tree:get(ctx.filter.cwd, function(node)
      local parent = node.parent and items[node.parent.path] or nil
      local note = zk.notes_cache[node.path] or nil
      local title = note and note.title
      local status = node.status or (parent and parent.dir_status)
      if node.dir and node.open and not opts.git_status_open then
        status = nil
      end
      local dirname, basename = node.path:match("(.*)/(.*)")
      dirname, basename = dirname or "", basename or node.path
      local severity = (not node.dir or not node.open or opts.diagnostics_open) and node.severity or nil

      ---@type snacks.picker.explorer.Item
      local item = {
        file = node.path,
        dir = node.dir,
        open = node.open,
        dir_status = node.dir_status or (parent and parent.dir_status),
        text = title or node.path,
        parent = parent,
        hidden = node.hidden or basename:sub(1, 1) == ".",
        ignored = node.ignored,
        status = status,
        type = node.type,
        severity = severity,
        -- last = true, -- DEBUG:
        last = node.last or nil,
      }
      -- if last[node.parent] then -- DEBUG: Breaks the tree icons (cause multiple `last = true`)
      --   last[node.parent].last = false
      -- end
      -- last[node.parent] = item
      -- DEBUG: --> May need customized code to get `last`, since the last item is drawn as `not last` when there are hidden items.

      if top == node then
        item.hidden = false
        item.ignored = false
      end

      -- DEBUG: Is this block needed ?
      -- item.text = item.text:sub(1, #opts.cwd) == opts.cwd and item.text:sub(#opts.cwd + 2) or item.text
      -- if node then
      --   item.dir = node.dir
      --   item.type = node.type
      --   item.status = (not node.dir or opts.git_status_open) and node.status or nil
      -- end

      item.zk = note or nil

      if item.zk and item.zk.title then
        item.text = item.zk.title
      else
        item.text = basename
      end

      cb(item)
      items[node.path] = item
    end, { hidden = opts.hidden, ignored = opts.ignored, exclude = opts.exclude, include = opts.include, expand = true })

    if not items[root.file] then
      cb(root)
    end
  end
end

---@param opts snacks.picker.zk.Config
---@type snacks.picker.finder
function M.search(opts, ctx)
  opts = Snacks.picker.util.shallow_copy(opts)
  opts.cwd = ctx.filter.cwd
  ctx.picker.list:set_target()

  ---@type snacks.picker.zk.Item
  local root = {
    file = opts.cwd,
    dir = true,
    open = true,
    text = "",
    sort = "",
    internal = true,
  }

  local dirs = {} ---@type table<string, snacks.picker.zk.Item>
  local last = {} ---@type table<snacks.picker.finder.Item, snacks.picker.finder.Item>
  local items = {} ---@type snacks.picker.zk.Item[]
  local notes_cache = require("snacks.zk").notes_cache

  ---@async
  return function(cb)
    cb(root)

    ---@param item snacks.picker.zk.Item
    local function add(item)
      local dirname, basename = item.file:match("(.*)/(.*)")
      dirname, basename = dirname or "", basename or item.file
      local parent = dirs[dirname] ~= item and dirs[dirname] or root

      item.sort = util.sort.get_sort_key(item, opts.cwd)
      item.hidden = basename:sub(1, 1) == "."
      item.text = item.text:sub(1, #opts.cwd) == opts.cwd and item.text:sub(#opts.cwd + 2) or item.text .. " +"

      if opts.tree then
        item.parent = parent
        if not last[parent] or last[parent].sort < item.sort then
          if last[parent] then
            last[parent].last = false
          end
          item.last = true
          last[parent] = item
        end
      end

      table.insert(items, item)
    end

    local function match(text, query, ignore_case)
      if ignore_case then
        return text:lower():find(query:lower(), 1, true)
      else
        return text:find(query, 1, true)
      end
    end

    -- Loop for notes_cache
    for path, note in pairs(notes_cache) do
      local match_query = ctx.filter.search
      local ignore_case = match_query:lower() == match_query
      local filename = vim.fn.fnamemodify(path, ":t")
      local title = (note.title or "")

      local matched_filename = match(filename, match_query, ignore_case)
      local matched_title = match(title, match_query, ignore_case)
      if matched_filename or matched_title then
        local is_dir = vim.fn.isdirectory(path) == 1 and true or false
        ---@type snacks.picker.zk.Item
        local item = {
          file = path,
          dir = is_dir,
          open = true,
          text = title ~= "" and title or filename,
          title = title ~= "" and note.title or nil,
        }

        -- Add parent directories recursively
        for dir in Snacks.picker.util.parents(item.file, opts.cwd) do
          if not dirs[dir] then
            ---@type snacks.picker.zk.Item
            local parent_item = {
              file = dir,
              text = dir,
              dir = true,
              open = true,
              internal = true,
              sort = "",
            }
            dirs[dir] = parent_item
            add(parent_item)
          end
        end
        if not item.dir then
          add(item)
        end
      end
    end

    local sorter = util.sort.get_sorter(opts)
    table.sort(items, sorter)

    for _, item in ipairs(items) do
      cb(item)
    end
  end
end

return M

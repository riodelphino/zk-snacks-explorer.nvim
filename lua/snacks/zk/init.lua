---@class snacks.zk
---@overload fun(opts?: snacks.picker.explorer.Config): snacks.Picker
local M = setmetatable({}, {
  __call = function(M, ...)
    return M.open(...)
  end,
})

M.meta = {
  desc = "A zk file explorer (picker in disguise)",
  needs_setup = true,
}

M.notes_cache = {}
M.notebook_path = nil

M.default_query = {
  desc = "All",
  query = {},
}
M.query = M.default_query

--- These are just the general explorer settings.
--- To configure the explorer picker, see `snacks.picker.explorer.Config`
---@class snacks.explorer.Config
local defaults = {
  replace_netrw = true, -- Replace netrw with the snacks explorer
}

---@param notes table
local function index_notes_by_path(notes)
  local tbl = {}
  for _, note in ipairs(notes) do
    tbl[note.absPath] = note
  end
  return tbl
end

---@param notes table
local function add_dir_to_notes(notes)
  for _, path in pairs(vim.tbl_keys(notes)) do
    for dir in vim.fs.parents(path) do
      if not notes[dir] then
        notes[dir] = { absPath = dir, is_dir = true }
      end
    end
  end
end

---Fetch and store zk info as M.notes_cache
---@param cb function?
function M.fetch_zk(cb)
  local zk_api = require("zk.api")
  local select = { select = { "absPath", "title", "filename" } }
  local zk_opts = vim.tbl_deep_extend("keep", select, M.query.query or {})
  zk_api.index(nil, zk_opts, function()
    zk_api.list(nil, zk_opts, function(err, notes)
      if err then
        vim.notify("Error: Cannot execute zk.api.list", vim.log.levels.ERROR)
      end
      M.notes_cache = index_notes_by_path(notes)
      add_dir_to_notes(M.notes_cache)
      if cb and type(cb) == "function" then
        vim.schedule(cb)
      end
    end)
  end)
end

---@private
---@param event? vim.api.keyset.create_autocmd.callback_args
function M.setup(event)
  local opts = Snacks.config.get("zk", defaults)

  if opts.replace_netrw then
    -- Disable netrw
    pcall(vim.api.nvim_del_augroup_by_name, "FileExplorer")

    local group = vim.api.nvim_create_augroup("snacks.zk", { clear = true })

    local function handle(ev)
      if ev.file ~= "" and vim.fn.isdirectory(ev.file) == 1 then
        local picker = M.open({ cwd = ev.file })
        if picker and vim.v.vim_did_enter == 0 then
          -- clear bufname so we don't try loading this one again
          vim.api.nvim_buf_set_name(ev.buf, "")
          picker:show()
          local ref = picker:ref()
          -- focus on UIEnter, since focusing before doesn't work
          vim.api.nvim_create_autocmd("UIEnter", {
            once = true,
            group = group,
            callback = function()
              local p = ref()
              if p then
                p:focus()
              end
            end,
          })
        else
          -- after vim has entered, we also need to delete the directory buffer
          -- use bufdelete to keep the window layout
          Snacks.bufdelete.delete(ev.buf)
        end
      end
    end

    -- event from snacks loader
    if event then
      handle(event)
    end

    -- TODO: Is this correct place to set notebook_path?
    zk_util = require("zk.util")
    M.notebook_path = zk_util.notebook_root(zk_util.resolve_notebook_path() or vim.fn.getcwd())

    -- Open the explorer when opening a directory
    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      callback = handle,
    })
  end
end

--- Shortcut to open the explorer picker
---@param opts? snacks.picker.explorer.Config|{}
function M.open(opts)
  M.fetch_zk(function()
    if not Snacks.picker.sources.zk then
      Snacks.picker.sources.zk = require("snacks.zk.source")
    end
    ---@type snacks.Picker
    local picker = Snacks.picker.zk(opts)
    M.update_picker_title(picker) -- Avoid 'picker is nil (==not generated yet)' error, by passing 'picker' as an argument.
  end)
end

--- Reveals the given file/buffer or the current buffer in the explorer
---@param opts? {file?:string, buf?:number}
function M.reveal(opts)
  local zk_actions = require("snacks.zk.actions")
  local Tree = require("snacks.zk.tree")
  opts = opts or {}
  local file = svim.fs.normalize(opts.file or vim.api.nvim_buf_get_name(opts.buf or 0))
  local picker = Snacks.picker.get({ source = "zk" })[1] or M.open()
  local cwd = picker:cwd()

  if not Tree:in_cwd(cwd, file) then
    for parent in vim.fs.parents(file) do
      if Tree:in_cwd(parent, cwd) then
        picker:set_cwd(parent)
        break
      end
    end
  end
  Tree:open(file)
  zk_actions.update(picker, { target = file, refresh = true })
  return picker
end

---Add current query description to picker title
---@param picker snacks.Picker?
function M.update_picker_title(picker)
  if not picker then
    picker = Snacks.picker.get({ source = "zk" })[1]
  end
  if not picker then
    return
  end
  local title
  if M.query.desc == "All" then
    title = "Zk"
  else
    title = string.format("Zk: %s", M.query.desc)
  end
  picker.title = title
  picker:update_titles()
end

return M

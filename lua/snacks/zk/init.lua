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
M.query = {}
M.notebook_path = nil

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

---Fetch and store zk info as M.notes_cache
---@param cb function?
function M.fetch_zk(cb)
  local zk_api = require("zk.api")
  local select = { select = { "absPath", "title", "filename" } }
  local zk_opts = vim.tbl_deep_extend("keep", select, M.query) -- DEBUG: merged query
  zk_api.index(nil, zk_opts, function()
    zk_api.list(nil, zk_opts, function(err, notes)
      if err then
        vim.notify("Error: Cannot execute zk.api.list", vim.log.levels.ERROR)
      end
      M.notes_cache = index_notes_by_path(notes)
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
    Snacks.picker.zk(opts)
  end)
end

--- Reveals the given file/buffer or the current buffer in the explorer
---@param opts? {file?:string, buf?:number}
function M.reveal(opts)
  local Actions = require("snacks.zk.actions")
  local Tree = require("snacks.zk.tree")
  opts = opts or {}
  local file = svim.fs.normalize(opts.file or vim.api.nvim_buf_get_name(opts.buf or 0))
  local zk_explorer = Snacks.picker.get({ source = "zk" })[1] or M.open()
  local cwd = zk_explorer:cwd()

  if not Tree:in_cwd(cwd, file) then
    for parent in vim.fs.parents(file) do
      if Tree:in_cwd(parent, cwd) then
        zk_explorer:set_cwd(parent)
        break
      end
    end
  end
  Tree:open(file)
  Actions.update(zk_explorer, { target = file, refresh = true })
  return zk_explorer
end

return M

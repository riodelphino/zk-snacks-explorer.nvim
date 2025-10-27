local M = {}

local Git = require("snacks.explorer.git")
local Tree = require("snacks.zk.tree")

M._watches = {} ---@type table<string, uv.uv_fs_event_t>

local uv = vim.uv or vim.loop
local timer = assert(uv.new_timer())

---@param path string
---@param cb? fun(file:string, events: uv.fs_event_start.callback.events)
function M.start(path, cb)
  if M._watches[path] ~= nil then
    return
  end
  local handle = assert(vim.uv.new_fs_event())
  local ok, err = handle:start(path, {}, function(_, file, events)
    file = path .. "/" .. file
    if cb then
      cb(file, events)
    else
      Tree:refresh(vim.fs.dirname(file))
      M.refresh()
    end
  end)
  M._watches[path] = handle
  if not ok then
    Snacks.notify.error("Failed to watch " .. path .. ": " .. err)
    if not handle:is_closing() then
      handle:close()
    end
    return
  end
end

---@param path string
function M.stop(path)
  local handle = M._watches[path]
  if handle then
    if not handle:is_closing() then
      handle:close()
    end
    M._watches[path] = nil
  end
end

-- Stop all watches
function M.abort()
  for path in pairs(M._watches) do
    M.stop(path)
  end
end

local refreshing = false

-- batch updates and give explorer the time to update before the watcher
function M.refresh()
  if refreshing then
    return
  end
  refreshing = true
  timer:start(
    100,
    0,
    vim.schedule_wrap(function()
      local picker = Snacks.picker.get({ source = "zk" })[1]
      if not picker or picker.closed then
        refreshing = false
        return
      end
      local zk = require("snacks.zk")
      zk.fetch_zk(function()
        if picker and not picker.closed then
          picker:find()
        end
        refreshing = false
      end)
    end)
  )
end

---@param cwd string
function M.watch(cwd)
  -- Track used watches
  local used = {} ---@type table<string, boolean>

  -- Watch git index
  local root = Snacks.git.get_root(cwd)
  if root then
    used[root .. "/.git"] = true
    M.start(root .. "/.git", function(file)
      if vim.fs.basename(file) == "index" then
        Git.refresh(root)
        M.refresh()
      end
    end)
  end

  -- Watch open directories
  Tree:walk(Tree:find(cwd), function(node)
    if node.dir and node.open then
      used[node.path] = true
      M.start(node.path)
    end
  end)

  -- Stop unused watches
  for path in pairs(M._watches) do
    if not used[path] then
      M.stop(path)
    end
  end
end

return M

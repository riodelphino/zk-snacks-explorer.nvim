local M = {}

---Returns true if the child is inside the parent dir
---@param path string
---@param dir string
---@return boolean
M.in_dir = function(path, dir)
  dir = vim.fs.normalize(dir)
  path = vim.fs.normalize(path)
  return path == dir or path:find(dir .. "/", 1, true) == 1
end

---Returns true if the path is inside the zk, or equal to it
---@param path string
---@return boolean
M.in_zk_dir = function(path)
  local notebook_path = M.get_notebook_path()
  if not notebook_path then
    return false
  end
  notebook_path = vim.fs.normalize(notebook_path)
  path = vim.fs.normalize(path)
  return M.in_dir(path, notebook_path)
end

---Get zk notebook path
---@return string?
M.get_notebook_path = function()
  local util = require("snacks.zk.util")
  local path = require("zk.util").notebook_root(M.get_cwd() or vim.fn.getcwd())
  return path
end

---Get cwd (Useful when ctx.filter.cwd or picker.cwd is not available)
---@return string?
M.get_cwd = function()
  local picker = require("snacks.zk.util").picker.get_picker()
  if picker then
    return picker.cwd(picker)
  else
    return vim.fn.getcwd()
  end
end

return M

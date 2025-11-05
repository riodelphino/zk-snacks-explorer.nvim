local M = {}

---Returns true if the child is inside the parent dir
---@param dir string
---@param path string
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
  local path = require("zk.util").notebook_root(util.picker.get_cwd() or vim.fn.getcwd())
  return path
end

return M

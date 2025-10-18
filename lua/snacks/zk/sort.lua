local zk = require("snacks.zk")

---@param a snacks.picker.explorer.Node
---@param b snacks.picker.explorer.Node
---@return boolean
local sorter = function(a, b)
  -- if a.name == "njcm06.md" then
  --   print("njcm06.md: C のやつね")
  -- end
  local an = zk.notes_cache[a.path] or nil
  local bn = zk.notes_cache[b.path] or nil
  local at = an and an.title
  local bt = bn and bn.title
  local a_has_title = (at ~= nil)
  local b_has_title = (bt ~= nil)
  local a_is_dot = (a.name:sub(1, 1) == ".")
  local b_is_dot = (b.name:sub(1, 1) == ".")
  if a.dir ~= b.dir then
    return a.dir
  end
  if a_is_dot ~= b_is_dot then
    return not a_is_dot
  end
  -- if an and an.title and an.title == "C" then
  --   print("a スペースなし: title=" .. an.title .. " name=" .. a.name)
  -- end
  if a_has_title ~= b_has_title then
    return a_has_title
  end

  if a_has_title and b_has_title then
    return at < bt
  end

  -- print("sorter: a: " .. vim.inspect(a))
  return a.name < b.name
  -- return true
end

return sorter

-- tree.lua から退避。Tree:walk_zk に入れるべきもの。あるいは外部関数化して呼び出す

-- table.sort(nodes, function(a, b)
--    -- 0. ルート優先
--    if a.dir and a.path == cwd then
--       return true
--    end
--    if b.dir and b.path == cwd then
--       return false
--    end
--
--    -- 1. ディレクトリ優先
--    if a.dir and not b.dir then
--       return true
--    end
--    if b.dir and not a.dir then
--       return false
--    end
--
--    local ta = (zk.notes_cache[a.path] and zk.notes_cache[a.path].title)
--    local tb = (zk.notes_cache[b.path] and zk.notes_cache[b.path].title)
--
--    local na = vim.fs.basename(a.path)
--    local nb = vim.fs.basename(b.path)
--
--    -- 2. タイトルの有無で優先
--    if ta and not tb then
--       return true
--    end
--    if tb and not ta then
--       return false
--    end
--
--    -- 3. ドットファイルは後方
--    local a_dot = na:match("^%.") or false
--    local b_dot = nb:match("^%.") or false
--    if a_dot and not b_dot then
--       return false
--    end
--    if b_dot and not a_dot then
--       return true
--    end
--
--    -- 4. タイトルがあればタイトルで比較、なければファイル名で比較
--    local sa = ta or na
--    local sb = tb or nb
--    return sa:lower() < sb:lower()
-- end)
--
-- for idx, n in ipairs(nodes) do
--    cb({
--       file = n.path,
--       dir = n.dir,
--       title = (zk.notes_cache[n.path] and zk.notes_cache[n.path].title) or vim.fs.basename(n.path),
--       idx = idx,
--       type = n.type,
--       parent = n.parent,
--    })
-- end
--

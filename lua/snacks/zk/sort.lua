-- TODO: What should do about following definitions?

-- ---@class snacks.picker.sorters
local M = {}

-- ---@class snacks.picker.sort.Config
-- ---@field fields? (snacks.picker.sort.Field|string)[]

---Returns a sorter function based on `opts.sort`
---Extended from lua/snacks/picker/sort.lua
---@param opts? snacks.picker.sort.Config
function M.default(opts)
  local fields = {} ---@type snacks.picker.zk.sort.Field[]
  for _, f in ipairs(opts and opts.fields or { { name = "score", desc = true }, "idx" }) do
    if type(f) == "string" then
      local desc, len, has = false, nil, nil
      if f:sub(1, 1) == "#" then
        f, len = f:sub(2), true
      end
      if f:sub(1, 1) == "!" then
        f, has = f:sub(2), true
      end
      if f:sub(-5) == ":desc" then
        f, desc = f:sub(1, -6), true
      elseif f:sub(-4) == ":asc" then
        f = f:sub(1, -5)
      end
      table.insert(fields, { name = f, desc = desc, len = len, has = has })
    else
      table.insert(fields, f)
    end
  end

  ---Get value from nested field name (e.g. "zk.metadata.created")
  ---@param a snacks.picker.zk.Node|snacks.picker.zk.Item
  ---@param b snacks.picker.zk.Node|snacks.picker.zk.Item
  return function(a, b)
    local function get_nested_value(obj, path)
      local val = obj
      for key in path:gmatch("[^%.]+") do
        if val == nil then
          return nil
        end
        val = val[key]
      end
      return val
    end

    for _, field in ipairs(fields) do
      local av = get_nested_value(a, field.name)
      local bv = get_nested_value(b, field.name)
      local a_has = av ~= nil
      local b_has = bv ~= nil
      local a_table = type(av) == "table"
      local b_table = type(bv) == "table"

      if a_has ~= b_has then
        return a_has
      elseif a_has and b_has then
        if field.len then
          av, bv = #av, #bv
        end
        if field.has then
          av, bv = a_has, b_has
        end
        if a_table or b_table then -- fallback to `has` if table
          av, bv = a_has, b_has
        end
        if av ~= bv then
          if type(av) == "boolean" then
            av, bv = av and 0 or 1, bv and 0 or 1
          end
          if field.desc then
            return av > bv
          else
            return av < bv
          end
        end
      end
    end
    return false
  end
end

function M.idx()
  ---@param a snacks.picker.zk.Node|snacks.picker.zk.Item
  ---@param b snacks.picker.zk.Node|snacks.picker.zk.Item
  return function(a, b)
    return a.idx < b.idx
  end
end

return M

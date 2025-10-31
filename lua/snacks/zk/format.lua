---@class snacks.picker.formatters
local M = {}

setmetatable(M, { __index = require("snacks.picker.format") }) -- Inherit from `snacks.picker.format`

local uv = vim.uv or vim.loop

---@param item snacks.picker.explorer.Item
---@param picker snacks.Picker
rawset(M, "filename", function(item, picker)
  ---@type snacks.picker.Highlight[]
  local ret = {}
  if not item.file then
    return ret
  end
  local path = Snacks.picker.util.path(item) or item.file
  path = Snacks.picker.util.truncpath(path, picker.opts.formatters.file.truncate or 40, { cwd = picker:cwd() })
  local name, cat = path, "file"
  if item.buf and vim.api.nvim_buf_is_loaded(item.buf) then
    name = vim.bo[item.buf].filetype
    cat = "filetype"
  elseif item.dir then
    cat = "directory"
  end

  if picker.opts.icons.files.enabled ~= false then
    local icon, hl = Snacks.util.icon(name, cat, {
      fallback = picker.opts.icons.files,
    })
    if item.dir and item.open then
      icon = picker.opts.icons.files.dir_open
    end
    icon = Snacks.picker.util.align(icon, picker.opts.formatters.file.icon_width or 2)
    ret[#ret + 1] = { icon, hl, virtual = true }
  end

  local base_hl = item.dir and "SnacksPickerDirectory" or "SnacksPickerFile"
  local function is(prop)
    local it = item
    while it do
      if it[prop] then
        return true
      end
      it = it.parent
    end
  end

  if is("ignored") then
    base_hl = "SnacksPickerPathIgnored"
  elseif is("hidden") then
    base_hl = "SnacksPickerPathHidden"
  elseif item.filename_hl then
    base_hl = item.filename_hl
  end
  local dir_hl = "SnacksPickerDir"

  local note = require("snacks.zk").notes_cache[item.file] or nil
  local title = note and note.title

  if picker.opts.formatters.file.filename_only then -- `filename` only (or title)
    path = vim.fn.fnamemodify(item.file, ":t")
    ret[#ret + 1] = { title or path, base_hl, field = "file" }
  else
    local dir, base = path:match("^(.*)/(.+)$")
    if base and dir then
      if picker.opts.formatters.file.filename_first then -- `filename dir` style
        ret[#ret + 1] = { base, base_hl, field = "file" }
        ret[#ret + 1] = { " " }
        ret[#ret + 1] = { dir, dir_hl, field = "file" }
      else
        ret[#ret + 1] = { dir .. "/", dir_hl, field = "file" } -- `dir/filename` style
        ret[#ret + 1] = { title or base, base_hl, field = "file" }
      end
    else
      ret[#ret + 1] = { title or base or path, base_hl, field = "file" } -- only `filename` or `dirname` (`/` was not included)
    end
  end
  if item.pos and item.pos[1] > 0 then
    ret[#ret + 1] = { ":", "SnacksPickerDelim" }
    ret[#ret + 1] = { tostring(item.pos[1]), "SnacksPickerRow" }
    if item.pos[2] > 0 then
      ret[#ret + 1] = { ":", "SnacksPickerDelim" }
      ret[#ret + 1] = { tostring(item.pos[2]), "SnacksPickerCol" }
    end
  end
  ret[#ret + 1] = { " " }
  if item.type == "link" then
    local real = uv.fs_realpath(item.file)
    local broken = not real
    real = real or uv.fs_readlink(item.file)
    if real then
      ret[#ret + 1] = { "-> ", "SnacksPickerDelim" }
      ret[#ret + 1] = { Snacks.picker.util.truncpath(real, 20), broken and "SnacksPickerLinkBroken" or "SnacksPickerLink" }
      ret[#ret + 1] = { " " }
    end
  end
  return ret
end)

rawset(M, "file", function(item, picker)
  ---@type snacks.picker.Highlight[]
  local ret = {}

  if item.label then
    ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
    ret[#ret + 1] = { " ", virtual = true }
  end

  if item.parent then
    vim.list_extend(ret, M.tree(item, picker))
  end

  if item.status then
    vim.list_extend(ret, M.file_git_status(item, picker))
  end

  if item.severity then
    vim.list_extend(ret, M.severity(item, picker))
  end

  vim.list_extend(ret, M.filename(item, picker))

  if item.comment then
    table.insert(ret, { item.comment, "SnacksPickerComment" })
    table.insert(ret, { " " })
  end

  if item.line then
    Snacks.picker.highlight.format(item, item.line, ret)
    table.insert(ret, { " " })
  end

  return ret
end)

return M

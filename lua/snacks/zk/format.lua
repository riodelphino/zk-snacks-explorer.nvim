local format = require("snacks.picker.format")

local M = {}

---@param item snacks.picker.Item
function M.zk_filename(item, picker)
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

   if picker.opts.formatters.file.filename_only then
      path = vim.fn.fnamemodify(item.file, ":t") .. " da" -- DEBUG: ここは何だ？
      ret[#ret + 1] = { path, base_hl, field = "file" }
   else
      local dir, base = path:match("^(.*)/(.+)$")
      local note = require("snacks.zk").notes_cache[item.file]
      local title = note and note.title
      if base and dir then
         if picker.opts.formatters.file.filename_first then
            ret[#ret + 1] = { base, base_hl, field = "file" } -- ここも？
            ret[#ret + 1] = { " " }
            ret[#ret + 1] = { dir, dir_hl, field = "file" }
         else
            ret[#ret + 1] = { dir .. "/", dir_hl, field = "file" }
            ret[#ret + 1] = { base, base_hl, field = "file" } -- ここも？
         end
      else
         ret[#ret + 1] = { title or path, base_hl, field = "file" } -- DEBUG: ここで note.title を表示できる
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
         ret[#ret + 1] =
            { Snacks.picker.util.truncpath(real, 20), broken and "SnacksPickerLinkBroken" or "SnacksPickerLink" }
         ret[#ret + 1] = { " " }
      end
   end
   return ret
end

function M.zk_file(item, picker)
   print("zk_file called")
   ---@type snacks.picker.Highlight[]
   local ret = {}

   if item.label then
      ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
      ret[#ret + 1] = { " ", virtual = true }
   end

   if item.parent then
      vim.list_extend(ret, format.tree(item, picker))
   end

   if item.status then
      vim.list_extend(ret, format.file_git_status(item, picker))
   end

   if item.severity then
      vim.list_extend(ret, format.severity(item, picker))
   end

   vim.list_extend(ret, format.zk_filename(item, picker))

   if item.comment then
      table.insert(ret, { item.comment, "SnacksPickerComment" })
      table.insert(ret, { " " })
   end

   if item.line then
      Snacks.picker.highlight.format(item, item.line, ret)
      table.insert(ret, { " " })
   end

   return ret
end

return M

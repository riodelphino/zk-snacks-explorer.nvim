local M = {}

---@param text string
---@param title? string
---@param opts? table
M.show_popup = function(text, title, opts)
  local lines = vim.split(text, "\n", { plain = true })

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  local height = #lines

  width = math.min(width + 4, math.floor(vim.o.columns * 0.9))
  height = math.min(height + 2, math.floor(vim.o.lines * 0.8))

  local winid = vim.api.nvim_get_current_win()
  local cfg = vim.api.nvim_win_get_config(winid)
  local zindex = (cfg.zindex or 50) + 1

  local defaults = {
    text = lines,
    title = title or nil,
    title_pos = "center",
    relative = "editor",
    position = "float",
    border = "rounded", -- TODO: Get these opts from Snacks defaults
    minimal = true,
    fixbuf = true,
    show = true,
    enter = true,
    focusable = true,
    width = width,
    height = height,
    zindex = zindex + 1,
    wo = {
      wrap = false,
      spell = false,
      statuscolumn = " ",
      conceallevel = 0,
    },
    bo = {
      modifiable = false,
    },
    scratch_ft = "snacks_zk_info",
    keys = {
      q = "close",
      ["<esc>"] = "close",
    },
  }
  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  Snacks.win(opts)
end

return M

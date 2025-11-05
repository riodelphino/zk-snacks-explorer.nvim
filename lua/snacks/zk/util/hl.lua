local M = {}

---@param hl_list table{string, vim.api.keyset.highlight}
M.set_highlights = function(hl_list)
  for hl_name, hl in pairs(hl_list) do
    vim.api.nvim_set_hl(0, hl_name, hl)
  end
end

return M

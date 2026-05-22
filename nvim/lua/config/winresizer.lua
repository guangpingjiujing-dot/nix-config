local step_v = 5
local step_h = 3

local function resize_mode()
  vim.api.nvim_echo({ { "-- RESIZE --", "ModeMsg" } }, false, {})

  while true do
    vim.cmd("redraw")
    local ok, char = pcall(vim.fn.getchar)
    if not ok then break end

    local key = type(char) == "number" and vim.fn.nr2char(char) or char
    local cur = vim.fn.winnr()

    if key == "h" then
      local left_nr = vim.fn.winnr("h")
      local right_nr = vim.fn.winnr("l")
      local has_left = left_nr ~= cur
      local has_right = right_nr ~= cur
      if has_left and has_right then
        -- 中央: 左に拡張
        vim.fn.win_move_separator(vim.fn.win_getid(left_nr), -step_v)
      elseif has_right then
        -- 左端: 縮小（右境界を左へ）
        vim.fn.win_move_separator(vim.fn.win_getid(), -step_v)
      elseif has_left then
        -- 右端: 左に拡張（左境界を左へ）
        vim.fn.win_move_separator(vim.fn.win_getid(left_nr), -step_v)
      end
    elseif key == "l" then
      local left_nr = vim.fn.winnr("h")
      local right_nr = vim.fn.winnr("l")
      local has_left = left_nr ~= cur
      local has_right = right_nr ~= cur
      if has_right then
        -- 中央・左端: 右に拡張
        vim.fn.win_move_separator(vim.fn.win_getid(), step_v)
      elseif has_left then
        -- 右端: 縮小（左境界を右へ）
        vim.fn.win_move_separator(vim.fn.win_getid(left_nr), step_v)
      end
    elseif key == "H" then
      local left_nr = vim.fn.winnr("h")
      if left_nr ~= cur then
        vim.fn.win_move_separator(vim.fn.win_getid(left_nr), step_v)
      end
    elseif key == "L" then
      local right_nr = vim.fn.winnr("l")
      if right_nr ~= cur then
        vim.fn.win_move_separator(vim.fn.win_getid(), -step_v)
      end
    elseif key == "j" then
      local down = vim.fn.winnr("j")
      if down ~= cur then
        vim.fn.win_move_statusline(vim.fn.win_getid(), step_h)
      end
    elseif key == "k" then
      local up = vim.fn.winnr("k")
      if up ~= cur then
        vim.fn.win_move_statusline(vim.fn.win_getid(up), -step_h)
      end
    elseif key == "q" or key == "\27" or key == "\13" then
      break
    end
  end

  vim.api.nvim_echo({ { "", "" } }, false, {})
end

vim.keymap.set({ "n", "i", "v" }, "<C-w>e", function()
  vim.cmd("stopinsert")
  resize_mode()
end, { desc = "Enter resize mode" })

vim.keymap.set("t", "<C-w>e", function()
  vim.cmd("stopinsert")
  resize_mode()
end, { desc = "Enter resize mode from terminal" })

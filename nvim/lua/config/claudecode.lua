require("claudecode").setup({
  diff_opts = {
    open_in_new_tab = true,
    hide_terminal_in_new_tab = false,
  },
})

-- Single-pane display for new file creation (no empty "before" pane)
local ok, diff_mod = pcall(require, "claudecode.diff")
if ok then
  local orig_create = diff_mod._create_diff_view_from_window
  diff_mod._create_diff_view_from_window = function(
    target_window, old_file_path, new_buffer, tab_name, is_new_file,
    terminal_win_in_new_tab, existing_buffer
  )
    if not is_new_file then
      return orig_create(
        target_window, old_file_path, new_buffer, tab_name, is_new_file,
        terminal_win_in_new_tab, existing_buffer
      )
    end

    if target_window then
      -- Non-new-tab mode: create diff normally, then close the empty left pane
      local result = orig_create(
        target_window, old_file_path, new_buffer, tab_name, is_new_file,
        terminal_win_in_new_tab, existing_buffer
      )
      if result.target_window and result.target_window ~= result.new_window
        and vim.api.nvim_win_is_valid(result.target_window)
      then
        pcall(vim.api.nvim_win_call, result.new_window, function() vim.cmd("diffoff") end)
        pcall(vim.api.nvim_win_close, result.target_window, true)
        if vim.api.nvim_win_is_valid(result.new_window) then
          vim.api.nvim_set_current_win(result.new_window)
        end
      end
      return result
    end

    -- New-tab mode (target_window == nil): place content in the current main window
    -- without creating any split. Terminal width was already set by display_terminal_in_new_tab.
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, new_buffer)

    local ft
    if vim.filetype and type(vim.filetype.match) == "function" then
      local ft_ok, detected = pcall(vim.filetype.match, { filename = old_file_path })
      if ft_ok then ft = detected end
    end
    if ft and ft ~= "" then
      vim.api.nvim_set_option_value("filetype", ft, { buf = new_buffer })
    end

    -- Green highlight on content lines only (not empty space below last line)
    vim.api.nvim_set_hl(0, "ClaudeCodeNewFileLine", { bg = "#1e3d20" })
    local ns = vim.api.nvim_create_namespace("claudecode_new_file")
    local line_count = vim.api.nvim_buf_line_count(new_buffer)
    for i = 0, line_count - 1 do
      vim.api.nvim_buf_set_extmark(new_buffer, ns, i, 0, {
        line_hl_group = "ClaudeCodeNewFileLine",
        priority = 100,
      })
    end

    vim.b[new_buffer].claudecode_diff_tab_name = tab_name
    vim.b[new_buffer].claudecode_diff_new_win = win
    vim.b[new_buffer].claudecode_diff_target_win = win

    return {
      new_window = win,
      target_window = nil,
      target_window_created_by_plugin = false,
      original_buffer = nil,
      original_buffer_created_by_plugin = false,
    }
  end
end

-- /copy コマンドが送る OSC 52 を Ghostty にパススルーする。
-- Neovim がこのシーケンスを内部処理すると改行が失われるため、
-- 外側のターミナルに転送して Ghostty に直接クリップボードへ書かせる。
vim.api.nvim_create_autocmd("TermRequest", {
  callback = function(args)
    if type(args.data) == "table" and args.data.sequence then
      local seq = args.data.sequence
      if seq:match("^\027]52;") then
        io.write(seq .. "\a")
        io.flush()
        return true
      end
    end
  end,
})

-- Diff view が開いたら最初の変更箇所にジャンプしてウィンドウ中央に表示
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    local name = vim.api.nvim_buf_get_name(0)
    if name:match("%[Claude Code%]") and name:match("%(proposed%)") then
      vim.schedule(function()
        vim.cmd("normal! gg]czz")
      end)
    end
  end,
})

-- proposed diff バッファで Insert モードに入ったら即 Normal モードに戻す
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    local name = vim.api.nvim_buf_get_name(0)
    if name:match("%[Claude Code%]") and name:match("%(proposed%)") then
      vim.schedule(function()
        vim.cmd("stopinsert")
      end)
    end
  end,
})

local function is_claude_visible()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf):lower():match("claude") then
      return true
    end
  end
  return false
end

-- README 推奨のキーバインド
-- <leader> = Space（init.lua で設定済み）
vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>",            { desc = "Toggle Claude" })
vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       { desc = "Focus Claude" })
vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   { desc = "Resume Claude" })
vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
vim.keymap.set("n", "<leader>ab", function()
  local visible = is_claude_visible()
  vim.cmd("ClaudeCodeAdd %")
  if visible then
    vim.schedule(function() vim.cmd("ClaudeCodeFocus") end)
  end
end, { desc = "Add current buffer" })
vim.keymap.set("n", "<leader>as", function()
  local visible = is_claude_visible()
  vim.cmd("ClaudeCodeAdd %")
  if visible then
    vim.schedule(function() vim.cmd("ClaudeCodeFocus") end)
  end
end, { desc = "Send to Claude (add buffer)" })
vim.keymap.set("v", "<leader>as", function()
  if not is_claude_visible() then
    vim.notify("Claude is not open", vim.log.levels.WARN)
    return
  end
  vim.cmd("ClaudeCodeSend")
  vim.schedule(function() vim.cmd("ClaudeCodeFocus") end)
end, { desc = "Send to Claude" })
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  { desc = "Accept diff" })
vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    { desc = "Deny diff" })

-- Claude Code ターミナルで <C-c> / <C-[> → ノーマルモードへ
-- <Esc> は意図的にマップしない（Claude 動作中の中断キーとして機能させるため）
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(ev)
    local name = vim.api.nvim_buf_get_name(ev.buf)
    if name:lower():match("claude") then
      vim.keymap.set("t", "<C-c>", "<C-\\><C-n>", { buffer = ev.buf })
      vim.keymap.set("t", "<C-[>", "<C-\\><C-n>", { buffer = ev.buf })
      -- <C-k> はグローバルではウィンドウ移動にマップされているが、
      -- zsh の kill-to-end-of-line として機能させるため直接送信する
      vim.keymap.set("t", "<C-k>", function()
        local chan = vim.b[ev.buf].terminal_job_id
        if chan then vim.fn.chansend(chan, "\11") end
      end, { buffer = ev.buf })
    end
  end,
})

-- ファイルツリー上での <leader>as でファイルを Claude に追加
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
  callback = function(ev)
    vim.keymap.set("n", "<leader>as", function()
      local visible = is_claude_visible()
      vim.cmd("ClaudeCodeTreeAdd")
      if visible then
        vim.schedule(function() vim.cmd("ClaudeCodeFocus") end)
      end
    end, { desc = "Add file", buffer = ev.buf })
  end,
})

local M = {}

local SEPARATOR = "# ── ここより上の内容を送信します " .. string.rep("─", 30)

local state = {
  channel_id = nil,
  channel_name = nil,
  thread_ts = nil,
  buf = nil,
  win = nil,
}

local function api_get(endpoint, params)
  local token = vim.env.SLACK_CLI_TOKEN or ""
  local url = "https://slack.com/api/" .. endpoint
  if params and params ~= "" then url = url .. "?" .. params end
  local out = vim.fn.system({ "curl", "-s", url, "-H", "Authorization: Bearer " .. token })
  local ok, data = pcall(vim.fn.json_decode, out)
  return ok and data or nil
end

local function api_post(endpoint, payload)
  local token = vim.env.SLACK_CLI_TOKEN or ""
  local out = vim.fn.system({
    "curl", "-s", "https://slack.com/api/" .. endpoint,
    "-H", "Authorization: Bearer " .. token,
    "-H", "Content-Type: application/json",
    "-d", vim.fn.json_encode(payload),
  })
  local ok, data = pcall(vim.fn.json_decode, out)
  return ok and data or nil
end

local CHANNELS_FILE = vim.fn.expand("~/.config/slack/channels.json")

local function load_users()
  local f = io.open("/tmp/slack-users.json", "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, content)
  return (ok and type(data) == "table") and data or {}
end

local function load_channels_from_file()
  local f = io.open(CHANNELS_FILE, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, content)
  return (ok and type(data) == "table") and data or nil
end

local function fetch_joined_channels()
  local channels = {}
  local cursor = ""
  while true do
    local params = "types=public_channel,private_channel,mpim,im&limit=1000&exclude_archived=true"
    if cursor ~= "" then params = params .. "&cursor=" .. cursor end
    local data = api_get("conversations.list", params)
    if not data or not data.ok then break end
    for _, ch in ipairs(data.channels or {}) do
      if ch.is_member then table.insert(channels, ch) end
    end
    cursor = (data.response_metadata and data.response_metadata.next_cursor) or ""
    if cursor == "" then break end
  end
  return channels
end

local function fmt_user(users, user_id, bot_name)
  if not user_id or user_id == "" then
    return (bot_name and bot_name ~= "") and bot_name or "system"
  end
  local name = users[user_id]
  if name and name ~= "" then return name .. " (" .. user_id .. ")" end
  if bot_name and bot_name ~= "" then return bot_name .. " (" .. user_id .. ")" end
  return user_id
end

local function fmt_ts(ts)
  local secs = tonumber((ts or ""):match("^(%d+)"))
  return secs and os.date("%m/%d %H:%M", secs) or "??/??"
end

local function msg_text(msg)
  if msg.text and msg.text ~= "" then return msg.text end
  if msg.attachments and msg.attachments[1] then
    return msg.attachments[1].pretext or msg.attachments[1].text or "(no text)"
  end
  return "(no text)"
end

-- スレッド履歴をコメント行として構築（新しい順）
local function build_comment_lines(channel_id, ts)
  local users = load_users()
  local data = api_get("conversations.replies", "channel=" .. channel_id .. "&ts=" .. ts)
  if not data or not data.ok then
    return { "# [エラー: " .. (data and data.error or "API error") .. "]" }
  end
  local msgs = data.messages
  local ch_name = state.channel_name or channel_id
  local lines = { SEPARATOR, "# channel : #" .. ch_name }
  for i = #msgs, 1, -1 do
    local msg = msgs[i]
    local bot_name = msg.bot_profile and msg.bot_profile.name
    local name = fmt_user(users, msg.user, bot_name)
    local time = fmt_ts(msg.ts)
    if i < #msgs then table.insert(lines, "#") end
    if i == 1 then table.insert(lines, "# ━━━ スレッド元 ━━━") end
    table.insert(lines, "# " .. time .. "  " .. name)
    for _, line in ipairs(vim.split(msg_text(msg), "\n", { plain = true })) do
      table.insert(lines, "#   " .. line)
    end
  end
  return lines
end

-- バッファの返信エリア（区切り線より上）を取得
local function get_reply_text()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return "" end
  local all_lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  local reply_lines = {}
  for _, line in ipairs(all_lines) do
    if line == SEPARATOR then break end
    table.insert(reply_lines, line)
  end
  while #reply_lines > 0 and reply_lines[#reply_lines]:match("^%s*$") do
    table.remove(reply_lines)
  end
  return table.concat(reply_lines, "\n")
end

-- バッファを最新スレッドで更新（返信エリアを維持したままコメント部分を書き換え）
local function refresh_comment_section()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  local all_lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  -- 区切り線の位置を探す
  local sep_idx = nil
  for i, line in ipairs(all_lines) do
    if line == SEPARATOR then sep_idx = i; break end
  end
  local reply_lines = sep_idx and vim.list_slice(all_lines, 1, sep_idx - 1) or all_lines
  local comment_lines = build_comment_lines(state.channel_id, state.thread_ts)
  local new_lines = vim.list_extend(reply_lines, comment_lines)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, new_lines)
  -- 返信エリアが空なら modified をリセット（:qa をブロックしない）
  local reply_text = table.concat(reply_lines, ""):gsub("%s", "")
  if reply_text == "" then
    vim.bo[state.buf].modified = false
  end
end

local function ensure_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then return end
  state.buf = vim.api.nvim_create_buf(true, false)
  pcall(vim.api.nvim_buf_set_name, state.buf, "Slack")
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = state.buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = state.buf })
  vim.api.nvim_set_option_value("filetype", "gitcommit", { buf = state.buf })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = state.buf,
    callback = function()
      M.send_reply()
      vim.api.nvim_set_option_value("modified", false, { buf = state.buf })
    end,
  })
end

local function find_main_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf):lower()
    if not name:match("claude") and not name:match("neo%-tree") then
      local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
      if bt == "" then return win end
    end
  end
  return nil
end

local function open_in_window()
  local target = find_main_win() or vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(target)
  vim.api.nvim_win_set_buf(target, state.buf)
  state.win = target
  vim.api.nvim_set_option_value("wrap", true, { win = state.win })
  vim.api.nvim_set_option_value("linebreak", true, { win = state.win })
end

function M.refresh()
  if not state.channel_id or not state.thread_ts then return end
  refresh_comment_section()
  pcall(vim.api.nvim_buf_set_name, state.buf,
    "Slack: #" .. (state.channel_name or state.channel_id))
  -- カーソルを先頭へ
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
  end
end

function M.send_reply()
  if not state.channel_id or not state.thread_ts then
    vim.notify("スレッドが選択されていません", vim.log.levels.WARN)
    return
  end
  local text = get_reply_text()
  if text:match("^%s*$") then
    vim.notify("メッセージが空です", vim.log.levels.WARN)
    return
  end
  local data = api_post("chat.postMessage", {
    channel = state.channel_id,
    text = text,
    thread_ts = state.thread_ts,
  })
  if data and data.ok then
    -- 返信エリアをクリアしてコメント部分を最新化
    local comment_lines = build_comment_lines(state.channel_id, state.thread_ts)
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, vim.list_extend({ "" }, comment_lines))
    vim.bo[state.buf].modified = false
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
    end
    vim.notify("送信しました")
  else
    vim.notify("エラー: " .. (data and data.error or "unknown"), vim.log.levels.ERROR)
  end
end

local function open_thread(channel_id, channel_name, ts)
  state.channel_id = channel_id
  state.channel_name = channel_name
  state.thread_ts = ts
  ensure_buf()
  open_in_window()
  -- 初期コンテンツ: 空行 + スレッド履歴コメント
  local comment_lines = build_comment_lines(channel_id, ts)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, vim.list_extend({ "" }, comment_lines))
  vim.bo[state.buf].modified = false
  pcall(vim.api.nvim_buf_set_name, state.buf, "Slack: #" .. (channel_name or channel_id))
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
  end
end

function M.pick()
  if not vim.env.SLACK_CLI_TOKEN or vim.env.SLACK_CLI_TOKEN == "" then
    vim.notify("SLACK_CLI_TOKEN が設定されていません", vim.log.levels.ERROR)
    return
  end

  local channels = load_channels_from_file()
  if channels then
    vim.notify("チャンネルリスト: " .. CHANNELS_FILE, vim.log.levels.INFO)
  else
    vim.notify("チャンネルを取得中（参加済みのみ）...", vim.log.levels.INFO)
    channels = fetch_joined_channels()
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Slack: チャンネルを選択",
    finder = finders.new_table({
      results = channels,
      entry_maker = function(ch)
        return {
          value = ch,
          display = "#" .. (ch.name or ch.id),
          ordinal = ch.name or ch.id,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(ch_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(ch_bufnr)
        if not entry then return end
        local ch = entry.value
        vim.schedule(function()
          local users = load_users()
          local data = api_get("conversations.history", "channel=" .. ch.id .. "&limit=30")
          if not data or not data.ok then
            vim.notify("メッセージの取得に失敗: " .. (data and data.error or "error"), vim.log.levels.ERROR)
            return
          end
          -- API は newest-first で返す → Telescope ではトップが古い、ボトムが新しい順になる
          local msgs = data.messages or {}
          pickers.new({}, {
            prompt_title = "Slack: #" .. (ch.name or ch.id),
            finder = finders.new_table({
              results = msgs,
              entry_maker = function(msg)
                local bot_name = msg.bot_profile and msg.bot_profile.name
                local name = fmt_user(users, msg.user, bot_name)
                local time = fmt_ts(msg.ts)
                local text = msg_text(msg):gsub("\n", " ")
                local thread = (msg.reply_count and msg.reply_count > 0)
                    and " [スレッド" .. msg.reply_count .. "件]" or ""
                local display = time .. "  " .. name .. "  " .. text .. thread
                return { value = msg, display = display, ordinal = display }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(msg_bufnr)
              actions.select_default:replace(function()
                local msg_entry = action_state.get_selected_entry()
                actions.close(msg_bufnr)
                if not msg_entry then return end
                vim.schedule(function()
                  open_thread(ch.id, ch.name or ch.id, msg_entry.value.ts)
                end)
              end)
              return true
            end,
          }):find()
        end)
      end)
      return true
    end,
  }):find()
end

vim.keymap.set("n", "<leader>sc", M.pick, { desc = "Slack: channel/thread picker" })
vim.keymap.set("n", "<leader>sr", M.refresh, { desc = "Slack: refresh thread" })
vim.keymap.set("n", "<leader>ss", M.send_reply, { desc = "Slack: send reply" })

return M

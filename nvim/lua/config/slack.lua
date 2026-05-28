local M = {}

local state = {
  channel_id = nil,
  channel_name = nil,
  thread_ts = nil,
  thread_buf = nil,
  reply_buf = nil,
  thread_win = nil,
  reply_win = nil,
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

local function load_users()
  local f = io.open("/tmp/slack-users.json", "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, content)
  return (ok and type(data) == "table") and data or {}
end

local function fmt_user(users, user_id, bot_name)
  if not user_id or user_id == "" then
    return (bot_name and bot_name ~= "") and bot_name or "system"
  end
  local name = users[user_id]
  if name and name ~= "" then
    return name .. " (" .. user_id .. ")"
  end
  if bot_name and bot_name ~= "" then
    return bot_name .. " (" .. user_id .. ")"
  end
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

local function build_thread_lines(channel_id, ts)
  local users = load_users()
  local data = api_get("conversations.replies", "channel=" .. channel_id .. "&ts=" .. ts)
  if not data or not data.ok then
    return { "[エラー: " .. (data and data.error or "API error") .. "]" }
  end
  local lines = {}
  for i, msg in ipairs(data.messages) do
    local bot_name = msg.bot_profile and msg.bot_profile.name
    local name = fmt_user(users, msg.user, bot_name)
    local time = fmt_ts(msg.ts)
    if i > 1 then table.insert(lines, "") end
    if i == 1 then table.insert(lines, "━━━ スレッド元 ━━━") end
    table.insert(lines, time .. "  " .. name)
    for _, line in ipairs(vim.split(msg_text(msg), "\n", { plain = true })) do
      table.insert(lines, "  " .. line)
    end
  end
  return lines
end

local function set_thread_content(lines)
  local buf = state.thread_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  if state.thread_win and vim.api.nvim_win_is_valid(state.thread_win) then
    local n = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(state.thread_win, { n, 0 })
  end
end

local function find_claude_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):lower()
    if name:match("claude") then return win end
  end
  return nil
end

local function find_main_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf):lower()
    if not name:match("claude") and not name:match("slack") and not name:match("neo%-tree") then
      local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
      if bt == "" then return win end
    end
  end
  return nil
end

local function set_win_opts(win)
  vim.api.nvim_set_option_value("wrap", true, { win = win })
  vim.api.nvim_set_option_value("linebreak", true, { win = win })
end

local function ensure_reply_buf()
  if state.reply_buf and vim.api.nvim_buf_is_valid(state.reply_buf) then return end
  state.reply_buf = vim.api.nvim_create_buf(false, false)
  pcall(vim.api.nvim_buf_set_name, state.reply_buf, "Slack Reply")
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = state.reply_buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = state.reply_buf })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = state.reply_buf,
    callback = function()
      M.send_reply()
      vim.api.nvim_set_option_value("modified", false, { buf = state.reply_buf })
    end,
  })
end

local function ensure_thread_buf()
  if state.thread_buf and vim.api.nvim_buf_is_valid(state.thread_buf) then return end
  state.thread_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.thread_buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.thread_buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = state.thread_buf })
end

local function ensure_layout()
  if state.thread_win and vim.api.nvim_win_is_valid(state.thread_win) and
     state.reply_win and vim.api.nvim_win_is_valid(state.reply_win) then
    return
  end

  ensure_reply_buf()
  ensure_thread_buf()

  -- 常に現在のタブで開く
  local base_win = find_main_win() or vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(base_win)

  -- Reply buffer in the base window (left)
  vim.api.nvim_win_set_buf(base_win, state.reply_buf)
  state.reply_win = base_win
  set_win_opts(state.reply_win)

  -- Thread buffer: vsplit to the right
  vim.cmd("rightbelow vsplit")
  vim.api.nvim_win_set_buf(0, state.thread_buf)
  state.thread_win = vim.api.nvim_get_current_win()
  set_win_opts(state.thread_win)

  local total = vim.o.columns
  local claude_win = find_claude_win()
  if claude_win then
    -- reply 25%, thread 45%, claude 残り
    vim.api.nvim_win_set_width(state.reply_win, math.floor(total * 0.25))
    vim.api.nvim_win_set_width(state.thread_win, math.floor(total * 0.45))
  else
    -- reply 35%, thread 残り
    vim.api.nvim_win_set_width(state.reply_win, math.floor(total * 0.35))
  end
end

function M.refresh()
  if not state.channel_id or not state.thread_ts then return end
  local lines = build_thread_lines(state.channel_id, state.thread_ts)
  set_thread_content(lines)
  pcall(vim.api.nvim_buf_set_name, state.thread_buf,
    "Slack: #" .. (state.channel_name or state.channel_id))
end

function M.send_reply()
  if not state.channel_id or not state.thread_ts then
    vim.notify("スレッドが選択されていません", vim.log.levels.WARN)
    return
  end
  if not state.reply_buf or not vim.api.nvim_buf_is_valid(state.reply_buf) then
    vim.notify("返信バッファが見つかりません", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(state.reply_buf, 0, -1, false)
  while #lines > 0 and lines[#lines]:match("^%s*$") do
    table.remove(lines)
  end
  local text = table.concat(lines, "\n")
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
    vim.api.nvim_buf_set_lines(state.reply_buf, 0, -1, false, {})
    M.refresh()
    vim.notify("送信しました")
  else
    vim.notify("エラー: " .. (data and data.error or "unknown"), vim.log.levels.ERROR)
  end
end

local function open_thread(channel_id, channel_name, ts)
  state.channel_id = channel_id
  state.channel_name = channel_name
  state.thread_ts = ts
  ensure_layout()
  if state.reply_buf and vim.api.nvim_buf_is_valid(state.reply_buf) then
    vim.api.nvim_buf_set_lines(state.reply_buf, 0, -1, false, {})
  end
  M.refresh()
  if state.reply_win and vim.api.nvim_win_is_valid(state.reply_win) then
    vim.api.nvim_set_current_win(state.reply_win)
  end
end

function M.pick()
  if not vim.env.SLACK_CLI_TOKEN or vim.env.SLACK_CLI_TOKEN == "" then
    vim.notify("SLACK_CLI_TOKEN が設定されていません", vim.log.levels.ERROR)
    return
  end

  local channels = {}
  local cursor = ""
  while true do
    local params = "types=public_channel,private_channel,mpim,im&limit=1000&exclude_archived=true"
    if cursor ~= "" then params = params .. "&cursor=" .. cursor end
    local data = api_get("conversations.list", params)
    if not data or not data.ok then break end
    vim.list_extend(channels, data.channels or {})
    cursor = (data.response_metadata and data.response_metadata.next_cursor) or ""
    if cursor == "" then break end
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
          local data = api_get("conversations.history", "channel=" .. ch.id .. "&limit=50")
          if not data or not data.ok then
            vim.notify("メッセージの取得に失敗: " .. (data and data.error or "error"), vim.log.levels.ERROR)
            return
          end

          local msgs = {}
          for i = #(data.messages or {}), 1, -1 do
            table.insert(msgs, data.messages[i])
          end

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
                return {
                  value = msg,
                  display = display,
                  ordinal = display,
                }
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

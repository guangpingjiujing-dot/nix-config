{ pkgs, slackToken, ... }:

{
  home.packages = with pkgs; [
    slack-cli
    fzf
  ];

  home.sessionVariables = {
    SLACK_CLI_TOKEN = slackToken;
  };

  programs.zsh.initContent = ''
    # fzf でチャンネルを選択してIDを返す（ページネーションで全チャンネル取得）
    _slack_pick_channel() {
      local cursor="" all_channels="" url response page
      while true; do
        url="https://slack.com/api/conversations.list?types=public_channel,private_channel,mpim,im&limit=1000&exclude_archived=true"
        [[ -n "$cursor" ]] && url="$url&cursor=$cursor"
        response=$(curl -s "$url" -H "Authorization: Bearer $SLACK_CLI_TOKEN")
        page=$(echo "$response" | jq -r '.channels[] | .id + "|#" + .name')
        all_channels="$all_channels$page"$'\n'
        cursor=$(echo "$response" | jq -r '.response_metadata.next_cursor // empty')
        [[ -z "$cursor" ]] && break
      done
      echo "$all_channels" | grep -v '^$' | \
        fzf --with-nth=2 --delimiter='|' --prompt='Channel> ' | \
        cut -d'|' -f1
    }

    # チャンネルのメッセージを色付きで表示（引数: [channel_id] [limit, デフォルト30]）
    # タイムスタンプ=シアン、ユーザー=黄、スレッド数=マゼンタ
    slack-read() {
      local channel="$1"
      local limit="$2"
      if [[ -z "$channel" ]]; then
        channel=$(_slack_pick_channel)
      fi
      [[ -z "$channel" ]] && return 1
      [[ -z "$limit" ]] && limit=30
      curl -s "https://slack.com/api/conversations.history?channel=$channel&limit=$limit" \
        -H "Authorization: Bearer $SLACK_CLI_TOKEN" \
        | jq -r '[.messages[]] | reverse[] |
            "\u001b[36m\(.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))\u001b[0m  \u001b[33m\(.user // .bot_id // "system")\u001b[0m  \(if .text != "" then .text else (.attachments[0].pretext // .attachments[0].text // "(no text)") end)\(if (.reply_count // 0) > 0 then "  \u001b[35m[スレッド\(.reply_count)件]\u001b[0m" else "" end)"'
    }

    # メッセージをfzfで選択してスレッド返信を色付きで表示（引数: [channel_id]）
    # スレッド元=緑、返信=インデント+シアン/黄
    slack-thread() {
      local channel="$1"
      if [[ -z "$channel" ]]; then
        channel=$(_slack_pick_channel)
      fi
      [[ -z "$channel" ]] && return 1
      local selected
      selected=$(curl -s "https://slack.com/api/conversations.history?channel=$channel&limit=50" \
        -H "Authorization: Bearer $SLACK_CLI_TOKEN" \
        | jq -r '[.messages[]] | reverse[] |
            .ts + "|" + "\(.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))  \(.user // .bot_id // "system")  \(if .text != "" then .text else (.attachments[0].pretext // .attachments[0].text // "(no text)") end)\(if (.reply_count // 0) > 0 then " [スレッド\(.reply_count)件]" else "" end)"' \
        | fzf --with-nth=2 --delimiter='|' --prompt='Message> ')
      [[ -z "$selected" ]] && return 1
      local ts
      ts=$(echo "$selected" | cut -d'|' -f1)
      curl -s "https://slack.com/api/conversations.replies?channel=$channel&ts=$ts" \
        -H "Authorization: Bearer $SLACK_CLI_TOKEN" \
        | jq -r '[.messages[]] | to_entries[] |
            if .key == 0 then
              "\u001b[32m\(.value.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))\u001b[0m  \u001b[32m\(.value.user // .value.bot_id // "system")\u001b[0m  \u001b[32m[スレッド元]\u001b[0m \(if .value.text != "" then .value.text else (.value.attachments[0].pretext // .value.attachments[0].text // "(no text)") end)"
            else
              "  \u001b[36m\(.value.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))\u001b[0m  \u001b[33m\(.value.user // .value.bot_id // "system")\u001b[0m  \(if .value.text != "" then .value.text else (.value.attachments[0].pretext // .value.attachments[0].text // "(no text)") end)"
            end'
    }

    # メッセージをfzfで選択してスレッドに返信（nvim縦分割: 左=スレッド参照 右=返信入力）
    # :wq で全ウィンドウを閉じて送信、:q! でキャンセル
    slack-reply() {
      local channel="$1"
      if [[ -z "$channel" ]]; then
        channel=$(_slack_pick_channel)
      fi
      [[ -z "$channel" ]] && return 1
      local selected
      selected=$(curl -s "https://slack.com/api/conversations.history?channel=$channel&limit=50" \
        -H "Authorization: Bearer $SLACK_CLI_TOKEN" \
        | jq -r '[.messages[]] | reverse[] |
            .ts + "|" + "\(.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))  \(.user // .bot_id // "system")  \(if .text != "" then .text else (.attachments[0].pretext // .attachments[0].text // "(no text)") end)\(if (.reply_count // 0) > 0 then " [スレッド\(.reply_count)件]" else "" end)"' \
        | fzf --with-nth=2 --delimiter='|' --prompt='Reply to> ')
      [[ -z "$selected" ]] && return 1
      local ts
      ts=$(echo "$selected" | cut -d'|' -f1)
      local threadfile tmpfile
      threadfile=$(mktemp /tmp/slack-thread-XXXXXX)
      tmpfile=$(mktemp /tmp/slack-reply-XXXXXX)
      curl -s "https://slack.com/api/conversations.replies?channel=$channel&ts=$ts" \
        -H "Authorization: Bearer $SLACK_CLI_TOKEN" \
        | jq -r '[.messages[]] | to_entries[] |
            if .key == 0 then
              "\(.value.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))  [スレッド元] \(.value.user // .value.bot_id // "system")\n\(if .value.text != "" then .value.text else (.value.attachments[0].pretext // .value.attachments[0].text // "(no text)") end)\n"
            else
              "\(.value.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))  \(.value.user // .value.bot_id // "system")\n\(if .value.text != "" then .value.text else (.value.attachments[0].pretext // .value.attachments[0].text // "(no text)") end)\n"
            end' > "$threadfile"
      nvim "$tmpfile" \
        -c "leftabove vsplit $threadfile" \
        -c "setlocal readonly nomodifiable bufhidden=wipe" \
        -c "wincmd l" \
        -c "autocmd QuitPre <buffer> qa"
      rm -f "$threadfile"
      local text
      text=$(cat "$tmpfile")
      rm -f "$tmpfile"
      [[ -z "$text" ]] && echo "Cancelled." && return 1
      curl -s "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer $SLACK_CLI_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"channel\":\"$channel\",\"text\":\"$text\",\"thread_ts\":\"$ts\"}" \
        | jq -r 'if .ok then "送信しました" else "エラー: \(.error)" end'
    }

    # fzf でチャンネルを選んでメッセージを送信（nvimで編集）
    slack-send() {
      local channel
      channel=$(_slack_pick_channel)
      [[ -z "$channel" ]] && return 1
      local tmpfile
      tmpfile=$(mktemp /tmp/slack-msg-XXXXXX)
      nvim "$tmpfile"
      local text
      text=$(cat "$tmpfile")
      rm -f "$tmpfile"
      [[ -z "$text" ]] && echo "Cancelled." && return 1
      slack chat send --text "$text" --channel "$channel"
    }
  '';
}

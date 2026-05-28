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
    # fzf でチャンネルを選択してIDを返す内部関数
    _slack_pick_channel() {
      curl -s "https://slack.com/api/conversations.list?types=public_channel,private_channel,mpim,im&limit=200&exclude_archived=true" \
        -H "Authorization: Bearer $SLACK_CLI_TOKEN" \
        | jq -r '.channels[] | .id + "|#" + .name' \
        | fzf --with-nth=2 --delimiter='|' --prompt='Channel> ' \
        | cut -d'|' -f1
    }

    # チャンネルのメッセージを表示（引数: [channel_id] [limit, デフォルト30]）
    # スレッドがある場合は [スレッドN件] を末尾に表示
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
            "\(.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))  \(.user // .bot_id // "system")  \(if .text != "" then .text else (.attachments[0].pretext // .attachments[0].text // "(no text)") end)\(if (.reply_count // 0) > 0 then " [スレッド\(.reply_count)件]" else "" end)"'
    }

    # メッセージをfzfで選択してスレッドの返信を表示（引数: [channel_id]）
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
        | jq -r '.messages[] |
            "\(.ts | split(".")[0] | tonumber | strftime("%m/%d %H:%M"))  \(.user // .bot_id // "system")  \(if .text != "" then .text else (.attachments[0].pretext // .attachments[0].text // "(no text)") end)"'
    }

    # fzf でチャンネルを選んでメッセージを送信
    slack-send() {
      local channel
      channel=$(_slack_pick_channel)
      [[ -z "$channel" ]] && return 1
      local text="$*"
      if [[ -z "$text" ]]; then
        echo -n "Message: "
        read text
      fi
      slack chat send --text "$text" --channel "$channel"
    }
  '';
}

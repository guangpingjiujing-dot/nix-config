---
description: Create ~/.config/slack/channels.json from a list of Slack channel names
when_to_use: Use when the user provides Slack channel names and wants to set up the channels.json file for fast channel selection in the Neovim Slack TUI (<leader>sc).
---

# slack-setup-channels

チャンネル名の一覧を受け取り、Slack API でIDを調べて `~/.config/slack/channels.json` を生成する。

## Input

引数として渡されたチャンネル名の一覧を使う。スペース・カンマ・改行のいずれかで区切られていてよい。`#` プレフィックスは除去して処理する。

引数がなければ、ユーザーにチャンネル名を入力するよう求める。

## 手順

### 1. トークン確認

```bash
echo $SLACK_CLI_TOKEN
```

空なら「`SLACK_CLI_TOKEN` が設定されていません。`local.nix` を確認してください。」と伝えて終了。

### 2. Slack API からチャンネル一覧を取得

ページネーションを繰り返して全チャンネルを収集し、`/tmp/slack-all-channels.json` に保存する。

```bash
# 1ページ目
curl -s "https://slack.com/api/conversations.list?types=public_channel,private_channel,mpim,im&limit=1000&exclude_archived=true" \
  -H "Authorization: Bearer $SLACK_CLI_TOKEN" > /tmp/slack-page1.json

# next_cursor があれば続ける
cursor=$(jq -r '.response_metadata.next_cursor // empty' /tmp/slack-page1.json)
# cursor が空になるまで繰り返し、全チャンネルを jq で結合して /tmp/slack-all-channels.json に保存
```

全ページ収集後、channels 配列だけを抽出：

```bash
jq '[.channels[] | {id, name}]' /tmp/slack-all-channels.json > /tmp/slack-all-channels.json
```

実際には各ページの `.channels` を結合してから保存すること。

### 3. チャンネル名をマッチング

ユーザーが指定した各チャンネル名について、大文字小文字を区別せずに名前を検索する。

```bash
jq --arg name "general" '.[] | select(.name | ascii_downcase == ($name | ascii_downcase))' /tmp/slack-all-channels.json
```

- 見つかったもの → 結果リストに追加
- 見つからなかったもの → 警告としてメモしておく
 
### 4. ~/.config/slack/channels.json を書き込む

```bash
mkdir -p ~/.config/slack
```

マッチしたチャンネルを以下の形式で書き込む：

```json
[
  {"id": "C01234567", "name": "general"},
  {"id": "C89012345", "name": "random"}
]
```

既存のファイルがある場合は上書きする前にユーザーに確認する。

### 5. 結果を報告

- 追加できたチャンネル（名前とID）
- 見つからなかったチャンネル名
- ファイルの書き込み先パス

を一覧で伝える。

## 完了後の使い方

Neovim で `<leader>sc` を押すと `~/.config/slack/channels.json` から読み込まれ、API 呼び出しなしで即座にチャンネル一覧が開く。

チャンネルを追加したい場合はこのスキルを再実行するか、ファイルを直接編集する。

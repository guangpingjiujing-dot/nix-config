# nix-config

macOS開発環境のdotfiles。Nixで環境を再現可能にすることを目的としている。

## セットアップ手順

### 1. Nixのインストール

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. このリポジトリをクローン

```bash
git clone <repo-url> ~/.config/nix-config
cd ~/.config/nix-config
```

### 3. ローカル設定ファイルを編集

マシン固有の設定（ユーザー名・アーキテクチャ）は `local.nix` に記述されている。
クローン後に自分の環境に合わせて編集する：

```nix
{
  username = "yourname";          # whoami で確認
  homeDirectory = "/Users/yourname";
  system = "aarch64-darwin";      # Intel Mac の場合は "x86_64-darwin"
  gitName = "Your Name";
  gitEmail = "your@email.com";
  slackToken = "xoxp-...";        # Slack API トークン（下記参照）
}
```

編集後、変更がgitに追跡されないよう設定する：

```bash
git update-index --skip-worktree local.nix
```

### 4. home-managerで環境を適用

```bash
home-manager switch --flake path:$(pwd)
```

### 5. 手動インストールが必要なもの

以下はNix管理外のため、別途インストールする：

| ツール | 理由 | 手順 |
|---|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | macOSのシステム統合が必要なため | 公式サイトから .dmg をダウンロード |
| Claude Code ステータスライン | `~/.claude/settings.json` はClaude Codeが書き込むためNix管理外 | 下記参照 |

#### Claude Code 設定（`~/.claude/settings.json`）

マシン固有の設定（会社用プラグイン等）が混在するためNix管理外。
`~/.claude/settings.json` に以下を追記する：

```json
{
  "theme": "dark",
  "verbose": true,
  "statusLine": {
    "type": "command",
    "command": "$HOME/.config/claude/statusline.sh",
    "refreshInterval": 30
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Submarine.aiff & sleep 0.5 && afplay /System/Library/Sounds/Submarine.aiff"
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Submarine.aiff",
            "async": true
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Read",
      "WebSearch",
      "WebFetch",
      "Bash(git *)",
      "Bash(gh *)",
      "Bash(ls *)",
      "Bash(find *)",
      "Bash(find * | head *)",
      "Bash(find * | grep *)",
      "Bash(grep *)",
      "Bash(rg *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(cat *)",
      "Bash(echo *)",
      "Bash(wc *)",
      "Bash(sort *)",
      "Bash(uniq *)",
      "Bash(cut *)",
      "Bash(tr *)",
      "Bash(awk *)",
      "Bash(sed *)",
      "Bash(jq *)",
      "Bash(diff *)",
      "Bash(xargs *)",
      "Bash(which *)",
      "Bash(mkdir *)",
      "Bash(touch *)",
      "Bash(source *)",
      "Bash(nix eval *)",
      "Bash(nix search *)",
      "Bash(ghostty *)",
      "Bash(starship *)",
      "Bash(just *)",
      "Bash(docker compose *)",
      "Bash(docker exec *)",
      "Bash(gcloud secrets list *)",
      "Bash(gcloud secrets versions list *)",
      "Bash(gcloud secrets versions access *)",
      "Bash(gcloud storage ls *)",
      "Bash(gcloud storage buckets describe *)",
      "Bash(gcloud storage buckets list *)",
      "Bash(gcloud storage objects describe *)",
      "Bash(gcloud storage cat *)",
      "Bash(gcloud storage buckets create *)",
      "Bash(gcloud storage buckets get-iam-policy *)",
      "Bash(gcloud config get-value *)",
      "Bash(gcloud config list *)",
      "Bash(gcloud config configurations list *)",
      "Bash(gcloud auth list *)",
      "Bash(gcloud projects list *)",
      "Bash(gcloud projects describe *)",
      "Bash(gcloud services list *)",
      "Bash(gcloud iam service-accounts list *)",
      "Bash(gsutil ls *)",
      "Bash(gsutil stat *)",
      "Bash(gsutil du *)",
      "Bash(gsutil cat *)",
      "Bash(gsutil version)",
      "Bash(bq ls *)",
      "Bash(bq show *)",
      "Bash(bq mk *)",
      "Bash(dbt --version)",
      "Bash(dbt compile *)",
      "Bash(dbt parse *)",
      "Bash(dbt ls *)",
      "Bash(dbt list *)",
      "Bash(dbt debug *)",
      "Bash(dbt deps *)",
      "Bash(dbt docs *)",
      "Bash(dbt seed *)",
      "Bash(dbt test *)"
    ]
  }
}
```

スクリプト本体（`~/.config/claude/statusline.sh`）は `home-manager switch` で自動的に配置される。

## Slack トークンの取得

`slack-cli` + zsh 関数でターミナルから Slack のメッセージ閲覧・送信ができる。
利用には Slack API トークンが必要。

### 1. Slack App を作成する

1. [api.slack.com/apps](https://api.slack.com/apps) にアクセスし「Create New App」→「From scratch」
2. App Name（任意）とワークスペースを設定して作成

### 2. OAuth スコープを追加する

左メニュー「OAuth & Permissions」→「User Token Scopes」に以下を追加：

| スコープ | 用途 |
|---|---|
| `channels:read` | パブリックチャンネル一覧 |
| `channels:history` | パブリックチャンネルのメッセージ読み取り |
| `groups:read` | プライベートチャンネル一覧 |
| `groups:history` | プライベートチャンネルのメッセージ読み取り |
| `im:read` | DM チャンネル一覧 |
| `im:history` | DM の読み取り |
| `mpim:read` | グループ DM 一覧 |
| `users:read` | ユーザー名の表示 |
| `chat:write` | メッセージの送信 |

### 3. トークンを発行する

「Install to Workspace」→ ワークスペースへのインストールを許可すると、
「User OAuth Token」（`xoxp-` で始まる文字列）が発行される。

### 4. local.nix に設定する

```nix
slackToken = "xoxp-xxxxxxxxxx-...";
```

設定後 `home-manager switch --flake path:$(pwd)` を実行するとトークンが環境変数 `SLACK_CLI_TOKEN` に設定される。

### ターミナルでの使い方

| コマンド | 操作 |
|---|---|
| `slack-read` | fzf でチャンネルを選択してメッセージ一覧を表示 |
| `slack-read <channel_id> <limit>` | チャンネルIDと件数を直接指定 |
| `slack-thread` | fzf でチャンネル→メッセージを選択してスレッド返信を表示 |
| `slack-send` | fzf でチャンネルを選択してメッセージを送信 |
| `slack-send "text"` | テキストを引数で直接渡して送信 |
| `slack-users-refresh` | ユーザー名キャッシュ（`/tmp/slack-users.json`）を強制更新 |

### Neovim での使い方

Telescope を使ったインタラクティブなスレッド閲覧・返信 UI。

| キー | 操作 |
|---|---|
| `<leader>sc` | Telescope でチャンネル → メッセージを選択してスレッドを開く |
| `<leader>sr` | 現在のスレッドを最新状態に更新 |
| `<leader>ss` | バッファの内容をスレッドに返信として送信 |
| `:w` | 同上（`:w` で送信） |

**チャンネルリストのカスタマイズ（`~/.config/slack/channels.json`）：**

`<leader>sc` はこのファイルが存在すればそこから読み込む（API 呼び出しなしで即座に開く）。
ファイルがない場合は参加済みチャンネルを API から取得する。

```json
[
  {"id": "C01234567", "name": "general"},
  {"id": "C89012345", "name": "random"}
]
```

チャンネル ID は Slack の URL（`slack://channel?id=C...`）またはチャンネル詳細画面で確認できる。

**UI の見た目（git commit メッセージスタイル）：**

```
ここに返信を書く

# ── ここより上の内容を送信します ──────────────────────────────
# channel : #general
#
# 12/01 10:30  たいてっく (U0ACHC1D9T6)
#   最新の返信内容
#
# 12/01 10:00  kouhei (U12345678)
#   その前の返信
#
# ━━━ スレッド元 ━━━
# 11/30 09:00  たいてっく (U0ACHC1D9T6)
#   スレッドの最初のメッセージ
```

区切り線より上に返信を書いて `:w` で送信。スレッド履歴は `#` コメントとして表示され、新しい順に並ぶ。

## 構成

```
nix-config/
├── flake.nix            # エントリーポイント・nixpkgsのバージョン固定
├── home.nix             # home-managerのルート（importsとhome.packages）
├── local.example.nix    # local.nix のテンプレート
├── local.nix            # マシン固有の設定（クローン後に編集する）
├── modules/
│   ├── claude.nix       # Claude Code（jq・ステータスラインスクリプト）
│   ├── ghostty.nix      # ターミナル（Ghostty）
│   ├── git.nix          # Git
│   ├── gh.nix           # GitHub CLI
│   ├── neovim.nix       # Neovim（プラグイン宣言のみ）
│   ├── slack.nix        # Slack CLI・環境変数（SLACK_CLI_TOKEN）
│   └── zsh.nix          # zsh・Starship
├── claude/
│   └── statusline.sh    # Claude Codeステータスライン（~/.config/claude/にリンク）
└── nvim/                # Neovim設定（Lua）
    ├── init.lua
    └── lua/config/
        ├── editor.lua       # autoread等の基本設定
        ├── colorscheme.lua  # TokyoNight
        ├── neo-tree.lua     # ファイルツリー
        ├── telescope.lua    # fuzzy finder
        ├── lualine.lua      # ステータスライン・カスタムタブライン
        ├── slack.lua        # Slack TUI（Telescope + スレッド返信バッファ）
        ├── toggleterm.lua   # フローティングターミナル
        ├── winresizer.lua   # ウィンドウリサイズ
        └── claudecode.lua   # Claude Code連携
```

## 環境を更新する

設定を変更したあとは以下を実行：

```bash
home-manager switch --flake path:$(pwd)
```

> **Note:** 新しいファイルを追加した場合は `git add` してから実行する（Nix flakeはgitで追跡されていないファイルを無視するため）。

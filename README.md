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
}
```

編集後、変更がgitに追跡されないよう設定する：

```bash
git update-index --skip-worktree local.nix
```

### 4. home-managerで環境を適用

```bash
nix run .#home-manager -- switch --flake .
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
      "Bash(nix eval *)",
      "Bash(nix search *)",
      "Bash(ghostty *)",
      "Bash(starship *)",
      "Bash(just *)",
      "Bash(docker compose *)",
      "Bash(docker exec *)",
      "Bash(gcloud secrets list *)",
      "Bash(gcloud storage ls *)",
      "Bash(gcloud storage buckets describe *)",
      "Bash(gcloud storage buckets list *)",
      "Bash(gcloud storage objects describe *)",
      "Bash(gcloud config get-value *)",
      "Bash(gcloud config list *)",
      "Bash(gcloud config configurations list *)",
      "Bash(gcloud auth list *)",
      "Bash(gcloud projects list *)",
      "Bash(gcloud projects describe *)",
      "Bash(gcloud services list *)",
      "Bash(gcloud iam service-accounts list *)",
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
        ├── lualine.lua      # ステータスライン・タブライン
        ├── toggleterm.lua   # フローティングターミナル
        ├── winresizer.lua   # ウィンドウリサイズ
        └── claudecode.lua   # Claude Code連携
```

## 環境を更新する

設定を変更したあとは以下を実行：

```bash
nix run .#home-manager -- switch --flake .
```

> **Note:** 新しいファイルを追加した場合は `git add` してから実行する（Nix flakeはgitで追跡されていないファイルを無視するため）。

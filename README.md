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

| ツール | 理由 | インストール先 |
|---|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | macOSのシステム統合が必要なため | 公式サイトから .dmg をダウンロード |

## 構成

```
nix-config/
├── flake.nix            # エントリーポイント・nixpkgsのバージョン固定
├── home.nix             # home-managerのルート（importsとhome.packages）
├── local.example.nix    # local.nix のテンプレート
├── local.nix            # マシン固有の設定（クローン後に編集する）
├── modules/
│   ├── ghostty.nix      # ターミナル（Ghostty）
│   ├── git.nix          # Git
│   ├── gh.nix           # GitHub CLI
│   ├── neovim.nix       # Neovim（プラグイン宣言のみ）
│   └── zsh.nix          # zsh・Starship
└── nvim/                # Neovim設定（Lua）
    ├── init.lua
    └── lua/config/
        ├── editor.lua       # autoread等の基本設定
        ├── colorscheme.lua  # TokyoNight
        ├── neo-tree.lua     # ファイルツリー
        └── claudecode.lua   # Claude Code連携
```

## 環境を更新する

設定を変更したあとは以下を実行：

```bash
nix run .#home-manager -- switch --flake .
```

> **Note:** 新しいファイルを追加した場合は `git add` してから実行する（Nix flakeはgitで追跡されていないファイルを無視するため）。

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

### 3. home-managerで環境を適用

```bash
nix run .#home-manager -- switch --flake .
```

### 4. 手動インストールが必要なもの

以下はNix管理外のため、別途インストールする：

| ツール | 理由 | インストール先 |
|---|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | macOSのシステム統合が必要なため | 公式サイトから .dmg をダウンロード |

## 構成

```
nix-config/
├── flake.nix          # エントリーポイント・nixpkgsのバージョン固定
├── home.nix           # home-managerのルート（importsとhome.packages）
├── modules/
│   ├── ghostty.nix    # ターミナル（Ghostty）
│   ├── git.nix        # Git
│   ├── gh.nix         # GitHub CLI
│   ├── neovim.nix     # Neovim（プラグイン宣言のみ）
│   └── zsh.nix        # zsh・Starship
└── nvim/              # Neovim設定（Lua）
    ├── init.lua
    └── lua/config/
        ├── editor.lua      # autoread等の基本設定
        ├── colorscheme.lua # TokyoNight
        ├── neo-tree.lua    # ファイルツリー
        └── claudecode.lua  # Claude Code連携
```

## 環境を更新する

設定を変更したあとは以下を実行：

```bash
nix run .#home-manager -- switch --flake .
```

> **Note:** 新しいファイルを追加した場合は `git add` してから実行する（Nix flakeはgitで追跡されていないファイルを無視するため）。

# Development Environment Setup

## Overview

This repository contains dotfiles and configuration for macOS development environment.
Configurations are designed to be portable across multiple Macs via GitHub.

## Environment

- **OS**: macOS
- **Terminal**: Ghostty
- **Editor**: Neovim

## Keybinding Policy

Prioritize default or widely-adopted keybindings so that the user can work effectively on other people's machines without relying on custom shortcuts.

- Avoid highly custom or personal keybindings
- Prefer Neovim/Vim defaults where possible
- When deviating from defaults, only adopt conventions that are common in the community (e.g., `<leader>` mappings that are standard in popular configs like LazyVim)

## Package Management

**All software and packages must be installed via Nix. Homebrew and other package managers are forbidden.**

- Use Nix to pin exact versions, ensuring identical environments across all Macs
- Version declarations live in the repo, so any machine cloning it gets the same packages

## File Structure

Nix設定はファイルを責任ごとに分割する：

```
nix-config/
├── flake.nix          # エントリーポイント
├── home.nix           # home-managerのルート（importsをまとめる）
└── modules/
    ├── neovim.nix
    ├── ghostty.nix
    ├── git.nix
    └── zsh.nix
```

- 「どのプラグインをインストールするか」→ Nix側で管理
- 「プラグインの細かい設定（Lua等）」→ 各ツールの設定ファイルで管理

## Goals

- Reproducible setup: any Mac should be configurable by cloning the repo
- Share on GitHub for portability
- Minimize friction when using unfamiliar machines

## Editing Rules

### Do NOT edit files under `~/.config/nvim/` directly

`home-manager switch`によってNixストア（`/nix/store/...`）にビルドされたファイルが`~/.config/nvim/`へシンボリックリンクされる。Nixストアはイミュータブルなので書き込み不可。

**常にこのリポジトリ内のソースファイルを編集すること：**

```
# 正しい編集対象
~/.config/nix-config/nvim/lua/config/lualine.lua  ✓

# 書き込み不可（シンボリックリンク先）
~/.config/nvim/lua/config/lualine.lua             ✗
```

編集後は`home-manager switch`で反映する。

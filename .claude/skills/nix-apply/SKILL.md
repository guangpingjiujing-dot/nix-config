---
description: Run home-manager switch to apply nix-config changes to the environment
when_to_use: Use after editing any file in nix-config/ to apply the changes. Required whenever the user asks to apply, reflect, or activate config changes. Also invoke when the user reports that a config change is not taking effect.
---

# nix-apply

nix-config への変更を実環境に反映するスキル。

## 適用コマンド

```bash
home-manager switch --flake ~/.config/nix-config
```

## 重要な仕組み

`xdg.configFile` の `source` オプションはファイルを **Nix ストアにコピー** し、そこへのシンボリックリンクを `~/.config/` に張る。

```
~/.config/nvim/... -> /nix/store/<hash>-home-manager-files/.config/nvim/...
```

`nix-config/` 内のファイルを直接参照しているわけではないため、**ファイルを編集しただけでは環境に反映されない。`home-manager switch` が必須。**

## 適用後の再起動

| 変更対象 | 必要な操作 |
|---|---|
| `nvim/` 以下の Lua ファイル | Neovim を再起動 |
| `modules/ghostty.nix` | Ghostty を再起動 |
| `modules/zsh.nix` | `exec zsh` |
| プラグイン追加・削除 | `home-manager switch` 後に Neovim を再起動 |

## よくある間違い

- 「Lua ファイルを編集したので Neovim の再起動だけでよい」→ **誤り**
- 「シンボリックリンクだから即座に反映される」→ **誤り**（リンク先は Nix ストアのスナップショット）

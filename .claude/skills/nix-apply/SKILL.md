---
description: Run home-manager switch to apply nix-config changes to the environment
when_to_use: Use after editing any file in nix-config/ to apply the changes. Required whenever the user asks to apply, reflect, or activate config changes. Also invoke when the user reports that a config change is not taking effect.
---

# nix-apply

nix-config への変更を実環境に反映するスキル。

## 適用手順

**新しいファイルを追加した場合**、先に `git add` が必要。Nix flake はステージされたファイルのみをビルドに含めるため、未追跡ファイルはNixストアに含まれない。

```bash
# 新規ファイルがある場合は先に git add
git add <新しいファイル>

# 適用（nix-configリポジトリのルートパスを使う）
# path: プレフィックスを必ず付ける（理由は下記参照）
home-manager switch --flake path:<nix-configのリポジトリルート>
```

リポジトリのルートパスは `git rev-parse --show-toplevel` で取得すること。パスをハードコードしてはいけない。

既存ファイルの編集のみの場合は `git add` 不要。

## `path:` プレフィックスが必須な理由

`--flake .` や `--flake /path/to/repo` は Nix が **git 経由**でソースツリーを読み込む。
このリポジトリでは `local.nix` が `git update-index --skip-worktree` で管理されているため、
git はディスク上の変更を無視してコミット済みのプレースホルダー値を返す。

`--flake path:/path/to/repo` にすると **git をバイパス**してディスク上の実ファイルを直接読むため、
`local.nix` の実際の値（トークン等）が正しく反映される。

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
- 「`home-manager switch` したのに新しいファイルが反映されない」→ `git add` 忘れ（untracked ファイルはビルドに含まれない）

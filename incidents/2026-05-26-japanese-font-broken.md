# 障害: Ghostty で日本語が文字化けする

**発生日**: 2026-05-26  
**解決日**: 2026-05-26  
**影響範囲**: Ghostty ターミナル全体の日本語表示（`。`→`°`、`、`→`'` のような文字化け）

---

## 症状

Ghostty で日本語の句読点が別の文字に化けて表示される。

| 本来の文字 | 化けた表示 |
|-----------|-----------|
| `。`（句点 U+3002）| `°`（度記号 U+00B0）|
| `、`（読点 U+3001）| `'`（右シングル引用符 U+2019）|

---

## 根本原因

**nerd-fonts パッケージ v3.4.0 でフォントの格納パスが変更された**ことと、**macOS 26 がシンボリックリンク経由のフォントを認識しない**ことが重なって発生。

### 経緯

1. **旧 ghostty.nix**（`home.file` による symlink 方式）:
   ```nix
   home.file."Library/Fonts/JetBrainsMonoNerdFont" = {
     source = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/JetBrainsMonoNerdFont";
     recursive = true;
   };
   ```
   この `truetype/JetBrainsMonoNerdFont` というパスは **nerd-fonts v3.3.x** までのもの。

2. **nerd-fonts v3.4.0 でパスが変更**:
   ```
   旧: share/fonts/truetype/JetBrainsMonoNerdFont/
   新: share/fonts/truetype/NerdFonts/JetBrainsMono/
   ```
   nixpkgs-unstable がこのバージョンを取り込んだ後、`home-manager switch` を実行すると旧パスへの symlink が壊れ、フォントが macOS から未登録状態になった。

3. **macOS 26 の制約**:
   - `~/Library/Fonts/` 以下に symlink を置くだけではフォントが認識されない
   - `CTFontManagerRegisterFontsForURL` の `.user` スコープも `-50 (paramErr)` で失敗する
   - フォントファイルを実際にコピーし、かつ macOS のフォントデーモンが検知するまで待つ必要がある

### 文字化けのメカニズム

JetBrainsMono が未登録 → Ghostty が代替フォントで描画 → その代替フォントで U+3002/U+3001 が意図しないグリフにマッピングされていた。

---

## 対処法

### ghostty.nix の修正

`home.file`（symlink 方式）を**廃止**し、`home.packages` に追加する方式に変更。

```nix
# home.nix に追加
home.packages = with pkgs; [
  ...
  nerd-fonts.jetbrains-mono
];
```

home-manager には macOS 向けのフォントインストール機能が組み込まれている（`modules/targets/darwin/fonts.nix`）。`home.packages` にフォントパッケージを追加すると、`rsync -acL --chmod=u+w` で実ファイルを `~/Library/Fonts/HomeManager/` にコピーする。

- symlink ではなく実ファイルとしてコピーされるため macOS 26 でも認識される
- フォントパッケージが更新されたとき自動で再コピーされる

### 適用手順

```bash
home-manager switch --flake ~/.config/nix-config
# その後 Ghostty を Cmd+Q で完全終了して再起動
```

---

## 教訓・注意点

- **nerd-fonts v3.4.0 以降は `pkgs.nerd-fonts.jetbrains-mono` という個別パッケージ API に変わった**（旧: `pkgs.nerdfonts.override { fonts = ["JetBrainsMono"]; }`）。パスも変わったので既存の `home.file` 参照はすべて壊れる。
- **macOS 26 以降は `~/Library/Fonts/` への symlink でフォントは登録されない**。home-manager の `home.packages` 経由（rsync で実ファイルコピー）を使うこと。
- フォント適用後は **Ghostty の完全再起動（Cmd+Q）が必要**。ウィンドウの閉じ開きだけでは不十分。

{ pkgs, ... }:

{
  # Nerd Fontをmacのフォントディレクトリに配置する
  # Nerd Fontとは: 通常のフォントにアイコン（グリフ）を追加した開発者向けフォント
  # Neovimでファイルツリーやステータスバーにアイコンを表示するために必要
  home.file."Library/Fonts/JetBrainsMonoNerdFont" = {
    source = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/JetBrainsMonoNerdFont";
    recursive = true;
  };

  # ~/Applications/ にシンボリックリンクを置く
  # Spotlightは ~/.nix-profile/Applications/ をインデックスしないため、
  # ~/Applications/ 経由にすることでSpotlight・Launchpadから起動できるようにする
  home.file."Applications/Ghostty.app".source = "${pkgs.ghostty-bin}/Applications/Ghostty.app";

  programs.ghostty = {
    enable = true;

    # pkgs.ghostty はmacOS非対応（Linuxのみ）のため、ghostty-bin を使う
    # ghostty-bin は公式の署名済み.dmgをNix用に再パッケージしたもの
    package = pkgs.ghostty-bin;

    settings = {
      # ターミナルのフォント
      # "Mono"サフィックスは等幅グリフを優先するバリアント（ターミナル向け）
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 14;
      font-feature = ["-liga" "-calt"];

      # カラーテーマ（Ghostty組み込みのテーマ名を指定）
      # 利用可能なテーマ一覧: ghostty +list-themes
      theme = "TokyoNight Night";

      # macOSタイトルバーのスタイル
      # native    : macOS標準のタイトルバー（デフォルト）
      # hidden    : タイトルバーを非表示
      # transparent: 透明なタイトルバー
      macos-titlebar-style = "native";

      # ウィンドウ内側の余白（px）
      # 文字がウィンドウ端に張り付かないよう少し余白を入れる
      window-padding-x = 10;
      window-padding-y = 10;

      # 背景の不透明度（0.0=完全透明 〜 1.0=完全不透明）
      # cmd+shift+o で 70% ↔ 100% をトグルできる
      background-opacity = 0.7;

      # 選択するだけでクリップボードにコピー
      copy-on-select = "clipboard";

      # 右クリック（2本指タップ）でクリップボードから貼り付け
      right-click-action = "paste";

      # ペインリサイズのキーバインド（デフォルト10から拡大）
      keybind = [
        "ctrl+cmd+left=resize_split:left,30"
        "ctrl+cmd+right=resize_split:right,30"
        "ctrl+cmd+up=resize_split:up,30"
        "ctrl+cmd+down=resize_split:down,30"
        "global:ctrl+`=toggle_quick_terminal"
        "cmd+i=prompt_tab_title"
        # デフォルトの super+arrow_right=text:\x05 (ctrl+e) を上書きする
        # \x05 はNeovimのターミナルモードでリサイズモードに入るキーバインドと衝突するため、
        # End キーシーケンス (\x1b[F) に変更して行末移動を維持しつつ衝突を回避する
        "super+arrow_right=text:\\x1b[F"
        # 背景不透明度トグル: 70%（半透明）↔ 100%（完全不透明）
        "cmd+shift+o=toggle_background_opacity"
      ];
    };
  };
}

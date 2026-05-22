{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    # $EDITOR, $VISUAL 環境変数を nvim に設定する
    defaultEditor = true;

    # RubyとPython3のサポートは不要なため無効化する（home-manager 26.05以降のデフォルト）
    withRuby = false;
    withPython3 = false;

    # Nix が管理するのは「どのプラグインを入れるか」だけ
    # 「プラグインをどう設定するか」は nvim/ 配下の Lua ファイルで管理する
    plugins = with pkgs.vimPlugins; [
      tokyonight-nvim

      neo-tree-nvim
      plenary-nvim       # neo-tree の依存ライブラリ
      nvim-web-devicons  # ファイルアイコン（Nerd Font が必要）
      nui-nvim           # neo-tree の UI コンポーネント

      telescope-nvim     # fuzzy finder
      telescope-fzf-native-nvim  # ネイティブ fzf ソーターで高速化

      lualine-nvim       # ステータスライン

      claudecode-nvim
      snacks-nvim        # claudecode-nvim の依存ライブラリ（ターミナル表示）

      toggleterm-nvim    # フローティングターミナル

      gitsigns-nvim      # git 差分をサインカラムに表示

      nvim-scrollbar     # スクロールバー

      (pkgs.vimUtils.buildVimPlugin {
        name = "accelerated-jk-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "rainbowhxch";
          repo = "accelerated-jk.nvim";
          rev = "8fb5dad4ccc1811766cebf16b544038aeeb7806f";
          hash = "sha256-zpjqCARlQU6g50s8wpaqN9xFK4tdUbrxU6MJrQZfSA8=";
        };
      })
    ];

  };

  # nix-config/nvim/ の内容を ~/.config/nvim/ にリンクする
  # recursive = true で nvim/ 内のファイルを1つずつリンク（ディレクトリごとではなく）
  xdg.configFile."nvim" = {
    source = ../nvim;
    recursive = true;
  };
}

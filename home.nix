{ pkgs, username, homeDirectory, ... }:

{
  imports = [
    # 各ツールの設定は責任ごとにファイルを分割してここでまとめる
    # 新しいツールを追加する際はmodules/配下にファイルを作成してimportする
    ./modules/claude.nix
    ./modules/gh.nix
    ./modules/ghostty.nix
    ./modules/git.nix
    ./modules/neovim.nix
    ./modules/slack.nix
    ./modules/vercel.nix
    ./modules/nvm.nix
    ./modules/zsh.nix
  ];

  # マシン固有の値は local.nix → flake.nix の extraSpecialArgs 経由で渡される
  home.username = username;
  home.homeDirectory = homeDirectory;

  # このhome-managerのバージョン設定
  # バージョンアップ時に後方互換性の変更を制御するために使用する
  # 基本的にはインストール時のhome-managerのバージョンに合わせて固定する
  home.stateVersion = "24.11";

  # home-manager自身をhome-managerで管理する（推奨設定）
  programs.home-manager.enable = true;

  # bq query のデフォルトを標準 SQL にする（レガシー SQL は廃止予定のため）
  home.file.".bigqueryrc".text = ''
    [query]
    --use_legacy_sql=false
    --maximum_bytes_billed=150000000000
  '';

  # home.packages: プログラム固有の設定が不要なツールをまとめてインストールする場所
  # 設定ファイルが必要なツールは modules/ 配下で programs.<name> として管理する
  home.packages = with pkgs; [
    claude-code        # Claude Code CLI
    tree               # ディレクトリ構造をツリー表示する
    uv                 # Python パッケージ・プロジェクト管理ツール
    ripgrep            # 高速 grep（rg コマンド）
    fd                 # 高速 find（fd コマンド）
    macism             # macOS 入力ソース切り替え CLI（Neovim の Insert 離脱時に ABC へ戻す）
    awscli2            # AWS CLI v2
    google-cloud-sdk   # Google Cloud CLI（gcloud, gsutil, bq）
    pyenv              # Python バージョン管理ツール
    nodejs             # Node.js（npm を含む）
    supabase-cli       # Supabase CLI（supabase コマンド）
    nb                 # CLIノート・ブックマーク管理ツール
    pyright            # Python LSP サーバー（pyright-langserver バイナリを含む）
    minikube           # ローカル Kubernetes クラスタ
    kubectl            # Kubernetes CLI
    sqlite             # SQLite CLI（sqlite3 コマンド）
    sling              # ELT ツール（データベース・ファイル間のデータ移動）
    nerd-fonts.jetbrains-mono  # JetBrainsMono Nerd Font（Ghostty・Neovim のアイコン表示に必要）

    # Python インタープリタ（複数バージョンをグローバルで利用可能にする）
    # python312 をデフォルトの python3 とし、他バージョンはバージョン付きバイナリのみ公開する。
    # 全バージョンをそのまま追加すると idle/python3 等のバイナリが衝突するため、
    # python3.11 / python3.13 はラッパー経由でバージョン固有のバイナリだけを公開する。
    python312
    (runCommand "python311-versioned" {} ''
      mkdir -p $out/bin
      ln -s ${python311}/bin/python3.11 $out/bin/python3.11
    '')
    (runCommand "python313-versioned" {} ''
      mkdir -p $out/bin
      ln -s ${python313}/bin/python3.13 $out/bin/python3.13
    '')
  ];
}

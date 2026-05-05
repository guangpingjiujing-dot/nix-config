{ pkgs, ... }:

{
  imports = [
    # 各ツールの設定は責任ごとにファイルを分割してここでまとめる
    # 新しいツールを追加する際はmodules/配下にファイルを作成してimportする
    ./modules/gh.nix
    ./modules/ghostty.nix
    ./modules/git.nix
    ./modules/zsh.nix
  ];

  # home-managerが管理するユーザー名とホームディレクトリ
  home.username = "kouheisakai";
  home.homeDirectory = "/Users/kouheisakai";

  # このhome-managerのバージョン設定
  # バージョンアップ時に後方互換性の変更を制御するために使用する
  # 基本的にはインストール時のhome-managerのバージョンに合わせて固定する
  home.stateVersion = "24.11";

  # home-manager自身をhome-managerで管理する（推奨設定）
  programs.home-manager.enable = true;
}

{ pkgs, ... }:

{
  # Visual Studio Code（unfree のため flake.nix の allowUnfree が必要）
  # アプリは ~/Applications/Home Manager Apps/ に配置される。
  # Nix ストアは書き込み不可なので VS Code 自身の自動アップデートは効かない。更新は nix flake update で行う。
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # 拡張機能や settings.json を Nix で管理する場合はここに追加する
    # profiles.default = {
    #   extensions = with pkgs.vscode-extensions; [ vscodevim.vim ];
    #   userSettings = { "editor.fontFamily" = "JetBrainsMono Nerd Font"; };
    # };
  };
}

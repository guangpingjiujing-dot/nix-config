{ pkgs, lib, ... }:

let
  nvm = pkgs.fetchFromGitHub {
    owner = "nvm-sh";
    repo = "nvm";
    rev = "v0.40.5";
    hash = "sha256-bcHoRW3BzvWZYwVyhtYWl8erpgOp4l30JW4XOaGZMQ0=";
  };
in
{
  # nvm.sh 本体だけ Nix ストアからリンクする。
  # ~/.nvm/versions/ などは nvm が実行時に書き込むため通常のディレクトリとして残す。
  home.file.".nvm/nvm.sh".source = "${nvm}/nvm.sh";
  home.file.".nvm/bash_completion".source = "${nvm}/bash_completion";

  home.sessionVariables.NVM_DIR = "$HOME/.nvm";

  programs.zsh.initContent = lib.mkAfter ''
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  '';
}

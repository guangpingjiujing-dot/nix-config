{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jq
  ];

  home.file.".config/claude/statusline.sh" = {
    source = ../claude/statusline.sh;
    executable = true;
  };
}
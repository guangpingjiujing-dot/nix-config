
{ inputs, ... }:

{
  imports = [
    inputs.hunk.homeManagerModules.default
  ];

  programs.hunk = {
    enable = true;
    enableGitIntegration = true; # Optional: set hunk as default git pager
    settings = {
      theme = "auto";
    };
  };
}

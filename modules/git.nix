{ gitName, gitEmail, ... }:

{
  programs.git = {
    enable = true;
    settings.user.name = gitName;
    settings.user.email = gitEmail;
    settings.init.defaultBranch = "main";
    settings.core.quotepath = false;
    settings.status.showUntrackedFiles = "all";
    settings.diff.colorMoved = "default";
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
    };
  };
}

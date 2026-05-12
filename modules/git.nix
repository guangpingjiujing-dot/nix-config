{ gitName, gitEmail, ... }:

{
  programs.git = {
    enable = true;
    settings.user.name = gitName;
    settings.user.email = gitEmail;
    settings.core.quotepath = false;
    settings.status.showUntrackedFiles = "all";
  };
}

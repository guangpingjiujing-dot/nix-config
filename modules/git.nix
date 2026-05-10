{ ... }:

{
  programs.git = {
    enable = true;
    settings.user.name = "guangpingjiujing-dot";
    settings.user.email = "guangpingjiujing@gmail.com";
    settings.core.quotepath = false;
    settings.status.showUntrackedFiles = "all";
  };
}

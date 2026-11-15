{ ... }:

{
  programs.hunk = {
    enable = true;
    enableGitIntegration = false; # Delta との競合を避けるため無効化（hunk を pager にしたい場合は true）
    enableClaudeIntegration = true; # ~/.claude/skills/hunk-review を配置
    settings = {
      theme = "auto";
    };
  };
}

{ lib, ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;
    settings = {
      font-family = "JetBrains Mono Nerd Font";
      font-size = 24;
      theme = "light:Rose Pine Dawn,dark:Rose Pine";
      background-opacity = 1;
      window-padding-x = 10;
      window-padding-y = 10;
      copy-on-select = true;
      mouse-hide-while-typing = true;
      confirm-close-surface = false;
      shell-integration = "zsh";
      shell-integration-features = "cursor,sudo,title";
      # AeroSpace owns alt-1..9; send tmux's M-1..9 from cmd-1..9 instead.
      keybind = map (n: "cmd+digit_${toString n}=text:\\x1b${toString n}") (lib.range 1 9);
    };
  };
}

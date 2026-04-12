_:
{
  programs.ghostty = {
    enable = true;
    package = null;
    enableZshIntegration = true;
    settings = {
      font-family = "JetBrains Mono Nerd Font";
      font-size = 18;
      theme = "light:Rose Pine Dawn,dark:Rose Pine";
      background-opacity = 1;
      window-padding-x = 10;
      window-padding-y = 10;
      copy-on-select = true;
      mouse-hide-while-typing = true;
      confirm-close-surface = false;
      shell-integration = "zsh";
      shell-integration-features = "cursor,sudo,title";
    };
  };
}

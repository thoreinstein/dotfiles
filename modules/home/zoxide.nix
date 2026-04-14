_:
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
    options = [
      "--cmd"
      "cd"
    ];
  };
}

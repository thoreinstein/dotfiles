_:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  xdg.configFile."nvim" = {
    source = ../../nvim/.config/nvim;
    recursive = true;
  };
}

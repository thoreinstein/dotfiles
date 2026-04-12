_:
{
  programs.bat = {
    enable = true;
    config = {
      theme = "rose-pine";
      style = "numbers,changes,header";
      italic-text = "always";
      paging = "auto";
      map-syntax = [
        "*.ino:C++"
        "*.yml:YAML"
        "*.yaml:YAML"
        "*.json:JSON"
      ];
      wrap = "auto";
    };
    themes = {
      rose-pine = {
        src = ../../bat/.config/bat/themes;
        file = "rose-pine.tmTheme";
      };
      rose-pine-moon = {
        src = ../../bat/.config/bat/themes;
        file = "rose-pine-moon.tmTheme";
      };
    };
  };
}

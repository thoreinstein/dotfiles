_:
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    # ──────────────────────────────────────────────
    # Taps
    # ──────────────────────────────────────────────
    taps = [ ];

    # ──────────────────────────────────────────────
    # Formulae
    # ──────────────────────────────────────────────
    brews = [
      "dolt"
    ];

    # ──────────────────────────────────────────────
    # Casks (GUI apps + fonts)
    # ──────────────────────────────────────────────
    casks = [
      "claude"
      "codexbar"
      "docker-desktop"
      "finicky"
      "ghostty"
      "obsidian"
      "utm"

      # Fonts
      "font-inter"
      "font-jetbrains-mono-nerd-font"
    ];
  };
}

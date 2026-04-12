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
    brews = [ ];

    # ──────────────────────────────────────────────
    # Casks (GUI apps + fonts)
    # ──────────────────────────────────────────────
    casks = [
      "claude"
      "claude-code"
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

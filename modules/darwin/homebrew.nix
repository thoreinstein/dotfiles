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
      "codex"
      "codexbar"
      "docker-desktop"
      "figma"
      "finicky"
      "ghostty"
      "obsidian"
      "utm"

      # Fonts
      "font-jetbrains-mono-nerd-font"
    ];
  };
}

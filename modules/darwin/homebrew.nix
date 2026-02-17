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
      "thoreinstein/tap/rig"
      "thoreinstein/tap/aix"
      "utm"

      # Fonts
      "font-jetbrains-mono-nerd-font"
    ];
  };
}

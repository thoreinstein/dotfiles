_: {
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
    taps = [
      {
        name = "gentleman-programming/tap";
        trusted = true;
      }
    ];

    # ──────────────────────────────────────────────
    # Formulae
    # ──────────────────────────────────────────────
    brews = [
    ];

    # ──────────────────────────────────────────────
    # Casks (GUI apps + fonts)
    # ──────────────────────────────────────────────
    casks = [
      "claude"
      "docker-desktop"
      "engram"
      "finicky"
      "gcloud-cli"
      "ghostty"
      "obsidian"
      "utm"

      # Fonts
      "font-inter"
    ];
  };
}

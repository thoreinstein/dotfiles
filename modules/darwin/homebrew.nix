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
      {
        name = "incoai/tap";
        trusted = true;
      }
    ];

    # ──────────────────────────────────────────────
    # Formulae
    # ──────────────────────────────────────────────
    brews = [
      "engram"
      "media-control"
    ];

    # ──────────────────────────────────────────────
    # Casks (GUI apps + fonts)
    # ──────────────────────────────────────────────
    casks = [
      "docker-desktop"
      "finicky"
      "ghostty"
      "obsidian"
      "utm"
    ];
  };
}

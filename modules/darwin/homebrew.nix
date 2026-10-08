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
      "splash"
    ];

    # ──────────────────────────────────────────────
    # Casks (GUI apps + fonts)
    # ──────────────────────────────────────────────
    casks = [
      "claude"
      "docker-desktop"
      "finicky"
      "gcloud-cli"
      "ghostty"
      "obsidian"
      "utm"
    ];
  };
}

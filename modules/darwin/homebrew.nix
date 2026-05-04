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
      "emarkou/prism"
      "gentleman-programming/tap"
    ];

    # ──────────────────────────────────────────────
    # Formulae
    # ──────────────────────────────────────────────
    brews = [
      "emarkou/prism/gh-prism"
      "mac-cleanup-go"
    ];

    # ──────────────────────────────────────────────
    # Casks (GUI apps + fonts)
    # ──────────────────────────────────────────────
    casks = [
      "claude"
      "codexbar"
      "docker-desktop"
      "engram"
      "finicky"
      "gcloud-cli"
      "ghostty"
      "obsidian"
      "utm"

      # Fonts
      "font-inter"
      "font-jetbrains-mono-nerd-font"
    ];
  };
}

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
    taps = [
      "atlassian/acli"
      "codefresh-io/cli"
      "hashicorp/tap"
      "steveyegge/beads"
      "supabase/tap"
      "thoreinstein/tap"
      "unrss/tap"
    ];

    # ──────────────────────────────────────────────
    # Formulae
    # ──────────────────────────────────────────────
    brews = [
      # GPG / YubiKey stack (macOS keychain + smart-card integration)
      "gnupg"
      "pinentry-mac"
      "ykman"
      "ykpers"

      # Custom taps (not in nixpkgs)
      "steveyegge/beads/bd"
      "opencode"

      # Go development
      "go"
      "golangci-lint"

      # Node / Python / Typst
      "node"
      "python@3.13"
      "uv"
      "typst"
      "tinymist"
      "typstyle"

      # Infrastructure / K8s
      "tflint"
      "kubernetes-cli"
      "kustomize"
      "kubeconform"
      "k9s"
      "stern"
      "jsonnet-bundler"

      # Database
      "postgresql@14"
      "redis"

      # Code quality (language-specific)
      "codespell"
      "lychee"
      "pre-commit"
      "shellcheck"
      "sqlfluff"
      "stylua"
      "yamllint"

      # Build / services
      "cmake"
      "doppler"
      "hugo"
      "jose"
      "mcp-toolbox"
      "overmind"
      "pkcs11-tools"
      "pkgconf"
      "protobuf"
      "repomix"
      "stripe-cli"
      "atlassian/acli/acli"
      "codefresh-io/cli/codefresh"
      "hashicorp/tap/terraform"
      "supabase/tap/supabase"
    ];

    # ──────────────────────────────────────────────
    # Casks (GUI apps + fonts)
    # ──────────────────────────────────────────────
    casks = [
      "bitwarden"
      "cascade"
      "claude"
      "cmake-app"
      "codex"
      "docker-desktop"
      "figma"
      "finicky"
      "gcloud-cli"
      "ghostty"
      "gpg-suite"
      "obsidian"
      "plex"
      "postman"
      "rig"
      "spotify"
      "temurin"
      "thoreinstein/tap/aix"
      "utm"

      # Fonts
      "font-cinzel"
      "font-cinzel-decorative"
      "font-eb-garamond"
      "font-jetbrains-mono-nerd-font"
    ];
  };
}

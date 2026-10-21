{ lib, pkgs, ... }:
{
  programs.pi-coding-agent = {
    enable = true;

    # The npm: and git: packages below (plus the one bare https://…git entry)
    # are fetched by pi at runtime and need node, bun, and git on pi's PATH.
    # The module wraps pi with --suffix, so an interactive shell's own bun
    # still takes precedence.
    extraPackages = [
      pkgs.nodejs
      pkgs.bun
      pkgs.git
    ];

    context = ./AGENTS.md;

    settings = {
      defaultTools = [ "+codemode" ];
      hideThinkingBlock = true;
      tuiMode = "fullscreen";
      collapseChangelog = true;
      quietStartup = true;
      enableInstallTelemetry = false;
      defaultThinkingLevel = "medium";
      showCacheMissNotices = true;
      externalEditor = "nvim";

      warnings.anthropicExtraUsage = true;

      # rose-pine-dawn above depends on the pi-rose-pine entry here.
      packages = [
        "git:github.com/apmantza/pi-lens"
        "git:github.com/ibragim-bad/evals-from-sessions"
        "git:github.com/thoreinstein/pi-obsidian"
        "npm:@firstpick/pi-extension-tools"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:@narumitw/pi-starship"
        "npm:gentle-engram"
        "npm:pi-caveman"
        "npm:pi-rtk-optimizer"
        "npm:pi-split-view"
      ];
    };
  };

  home.file = {
    ".pi/agent/extensions/agent-resume.ts".source = ./agent-resume.ts;
    ".pi/agent/extensions/pi-guard.ts".source = ./pi-guard.ts;
    ".pi/agent/extensions/pi-notify.ts".source = ./pi-notify.ts;
    ".pi/agent/skills/pr-review/SKILL.md".source = ./skills/pr-review/SKILL.md;
  };

  # pi-starship refuses a symlinked settings file, so copy it in as a regular file.
  home.activation.piStarshipConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run rm -f "$HOME/.pi/agent/pi-starship.toml"
    run install -m 644 ${./starship.toml} "$HOME/.pi/agent/pi-starship.toml"
  '';
}

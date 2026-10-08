{ pkgs, ... }:
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
      collapseChangelog = true;
      quietStartup = true;
      enableInstallTelemetry = false;
      defaultThinkingLevel = "medium";
      showCacheMissNotices = true;
      externalEditor = "nvim";

      warnings.anthropicExtraUsage = true;

      # rose-pine-dawn above depends on the pi-rose-pine entry here.
      packages = [
        "git:github.com/DietrichGebert/ponytail"
        "git:github.com/apmantza/pi-lens"
        "git:github.com/ferologics/pi-notify"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:@narumitw/pi-starship"
        "npm:gentle-engram"
        "npm:pi-caveman"
        "npm:pi-rtk-optimizer"
        "git:github.com/thoreinstein/pi-obsidian"
      ];
    };
  };

  home.file = {
    ".pi/agent/extensions/pi-guard.ts".source = ./pi-guard.ts;
    ".pi/agent/skills/pr-review/SKILL.md".source = ./skills/pr-review/SKILL.md;
    ".pi/agent/pi-starship.toml".source = ./starship.toml;
  };
}

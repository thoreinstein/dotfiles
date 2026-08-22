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
      theme = "rose-pine-dawn";
      hideThinkingBlock = true;
      collapseChangelog = true;
      quietStartup = true;
      enableInstallTelemetry = false;
      defaultThinkingLevel = "high";
      showCacheMissNotices = true;
      externalEditor = "nvim";

      warnings.anthropicExtraUsage = true;

      # rose-pine-dawn above depends on the pi-rose-pine entry here.
      packages = [
        "git:github.com/DietrichGebert/ponytail"
        "git:github.com/apmantza/pi-lens"
        "git:github.com/ferologics/pi-notify"
        "https://github.com/zenobi-us/pi-rose-pine.git"
        "npm:@joemccann/pi-exa"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:@juicesharp/rpiv-todo"
        "npm:@narumitw/pi-plan-mode"
        "npm:@narumitw/pi-starship"
        "npm:context-mode"
        "npm:gentle-engram@0.1.8"
        "npm:pi-bash-live-view"
        "npm:pi-caveman"
        "npm:pi-continuous-learning"
        "npm:pi-mcp-adapter"
        "npm:pi-rtk-optimizer"
        "npm:pi-subagents"
      ];
    };
  };

  home.file = {
    ".pi/agent/extensions/guardrails.ts".source = ./guardrails.ts;
    ".pi/agent/pi-starship.toml".source = ./starship.toml;
  };
}

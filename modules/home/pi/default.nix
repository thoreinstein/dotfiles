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
      compaction = {
        enabled = true;
        reserveTokens = 16384;
        keepRecentTokens = 20000;
      };

      theme = "rose-pine-dawn";
      hideThinkingBlock = true;
      collapseChangelog = true;
      quietStartup = true;
      enableInstallTelemetry = false;
      defaultThinkingLevel = "medium";

      # rose-pine-dawn above depends on the pi-rose-pine entry here.
      packages = [
        "git:github.com/apmantza/pi-lens"
        "git:github.com/ferologics/pi-notify"
        "https://github.com/zenobi-us/pi-rose-pine.git"
        "npm:@joemccann/pi-exa"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:@narumitw/pi-plan-mode"
        "npm:context-mode"
        "npm:pi-bash-live-view"
        "npm:pi-caveman"
        "npm:pi-continuous-learning"
        "npm:pi-mcp-adapter"
        "npm:pi-rtk-optimizer"
        "npm:pi-memory"
      ];
    };
  };
}

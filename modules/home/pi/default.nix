{ config, lib, pkgs, ... }:
let
  # Tool shorthands from zsh that agents type too. Aliases that swap a standard command
  # (cat -> bat, ls -> eza) stay out: they change output the agent parses.
  agentAliases = lib.getAttrs [ "k" "tf" "tg" ] config.programs.zsh.shellAliases;
in
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

      # pi runs each command with a non-interactive `bash -c`: no aliases, and no direnv hook,
      # so a worktree's .envrc (mise tools, env vars) never loads after a cd. Load both per command,
      # and again after any cd inside it (`cd worktree && tg plan`).
      shellCommandPrefix = ''
        shopt -s expand_aliases
        source ~/.pi/agent/bash_aliases
        cd() { builtin cd "$@" && eval "$(direnv export bash 2>/dev/null)"; }
        eval "$(direnv export bash 2>/dev/null)"'';

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
        "npm:pi-rewind"
        "npm:pi-rtk-optimizer"
        "npm:pi-split-view"
      ];
    };
  };

  home.file = {
    ".pi/agent/bash_aliases".text = lib.concatStrings (
      lib.mapAttrsToList (n: v: "alias ${n}=${lib.escapeShellArg v}\n") agentAliases
    );
    ".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;
    ".pi/agent/extensions/agent-resume.ts".source = ./agent-resume.ts;
    ".pi/agent/extensions/pi-guard.ts".source = ./pi-guard.ts;
    ".pi/agent/extensions/pi-notify.ts".source = ./pi-notify.ts;
    ".pi/agent/skills/ci-fix/SKILL.md".source = ./skills/ci-fix/SKILL.md;
    ".pi/agent/skills/compound/SKILL.md".source = ./skills/compound/SKILL.md;
    ".pi/agent/skills/plan-review/SKILL.md".source = ./skills/plan-review/SKILL.md;
    ".pi/agent/skills/pr-review/SKILL.md".source = ./skills/pr-review/SKILL.md;
    ".pi/agent/skills/rebase/SKILL.md".source = ./skills/rebase/SKILL.md;
    ".pi/agent/skills/standup/SKILL.md".source = ./skills/standup/SKILL.md;
    ".pi/agent/skills/wrap-up/SKILL.md".source = ./skills/wrap-up/SKILL.md;
  };

  # pi-starship refuses a symlinked settings file, so copy it in as a regular file.
  home.activation.piStarshipConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run rm -f "$HOME/.pi/agent/pi-starship.toml"
    run install -m 644 ${./starship.toml} "$HOME/.pi/agent/pi-starship.toml"
  '';
}

{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "agent-resume";
      runtimeInputs = [ pkgs.tmux ];
      text = builtins.readFile ../../bin/.bin/agent-resume;
    })
    (pkgs.writeShellApplication {
      name = "codegraph-nudge";
      runtimeInputs = with pkgs; [ jq git gnused ];
      text = builtins.readFile ../../bin/.bin/codegraph-nudge;
    })
    (pkgs.writeShellApplication {
      name = "claude-work-guard";
      runtimeInputs = with pkgs; [ jq gnugrep coreutils ];
      text = builtins.readFile ../../bin/.bin/claude-work-guard;
    })
    (pkgs.writeShellApplication {
      name = "git-bypass-guard";
      runtimeInputs = with pkgs; [ jq gnugrep gnused ];
      text = builtins.readFile ../../bin/.bin/git-bypass-guard;
    })
    (pkgs.writeShellApplication {
      name = "gauth";
      # gcloud comes from PATH: cli.nix installs the SDK with extra components.
      runtimeInputs = with pkgs; [ fzf coreutils gawk ];
      text = builtins.readFile ../../bin/.bin/gauth;
    })
    (pkgs.writeShellApplication {
      name = "ghclone";
      runtimeInputs = with pkgs; [ git coreutils gnugrep gnused findutils ];
      text = builtins.readFile ../../bin/.bin/ghclone;
    })
    (pkgs.writeShellApplication {
      name = "now-playing";
      # media-control has no nixpkgs source; homebrew.nix installs it.
      runtimeInputs = [ pkgs.jq ];
      text = builtins.readFile ../../bin/.bin/now-playing;
    })
    # Standard library only, so no vendor hash; `go test` runs during the build.
    # engram, node and claude-work-guard come from PATH at run time.
    (pkgs.buildGoModule {
      pname = "recall";
      version = "0.1.0";
      src = ../../bin/recall;
      vendorHash = null;
    })
    (pkgs.writeShellApplication {
      name = "ts";
      # sysctl (macOS CPU count) has no nixpkgs source; it stays on the system
      # PATH with a fallback. find falls back the same way when fd is absent.
      runtimeInputs = with pkgs; [ tmux git fzf fd coreutils gnugrep findutils ];
      text = builtins.readFile ../../bin/.bin/ts;
    })
    (pkgs.writeShellApplication {
      name = "weekly";
      runtimeInputs = [ pkgs.sqlite ];
      text = builtins.readFile ../../bin/.bin/weekly;
    })
  ];
}

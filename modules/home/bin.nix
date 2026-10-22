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
      name = "ghclone";
      runtimeInputs = with pkgs; [ git coreutils gnugrep gnused findutils ];
      text = builtins.readFile ../../bin/.bin/ghclone;
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

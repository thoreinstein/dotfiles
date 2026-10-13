{ pkgs, username, homeDirectory, ... }:
let
  engramVaultSync = pkgs.writeShellApplication {
    name = "engram-vault-sync";
    runtimeInputs = [ pkgs.rsync ];
    text = builtins.readFile ../../bin/.bin/engram-vault-sync;
  };
  engramDailyLog = pkgs.writeShellApplication {
    name = "engram-daily-log";
    text = builtins.readFile ../../bin/.bin/engram-daily-log;
  };
  # engram is installed by homebrew and claude by nix (or its own installer on hosts that
  # don't nix-manage it); none of these are on launchd's default PATH
  agentPath = "/opt/homebrew/bin:/etc/profiles/per-user/${username}/bin:${homeDirectory}/.local/bin:/usr/bin:/bin";
in
{
  home.packages = [ engramVaultSync engramDailyLog ];

  launchd.agents = {
    engram-vault-sync = {
      enable = true;
      config = {
        ProgramArguments = [ "${engramVaultSync}/bin/engram-vault-sync" ];
        EnvironmentVariables.PATH = agentPath;
        StartInterval = 900;
        RunAtLoad = true;
        StandardErrorPath = "${homeDirectory}/.cache/engram-vault-sync.log";
      };
    };

    engram-daily-log = {
      enable = true;
      config = {
        ProgramArguments = [ "${engramDailyLog}/bin/engram-daily-log" ];
        EnvironmentVariables.PATH = agentPath;
        StartInterval = 3600;
        RunAtLoad = true;
        StandardErrorPath = "${homeDirectory}/.cache/engram-daily-log.log";
      };
    };
  };
}

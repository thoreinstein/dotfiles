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
  agentEnv = {
    # engram is installed by homebrew and claude by nix; neither is on launchd's default PATH
    PATH = "/opt/homebrew/bin:/etc/profiles/per-user/${username}/bin:${homeDirectory}/.local/bin:/usr/bin:/bin";
    # claude-code 2.1.308+ lost its bundled root store on macOS, and sessionVariables reach
    # shells but not launchd agents (engram-daily-log shells out to claude). Drop once
    # upstream ships a fix (2.1.303 and earlier didn't need it).
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
  };
in
{
  home.packages = [ engramVaultSync engramDailyLog ];

  launchd.agents = {
    engram-vault-sync = {
      enable = true;
      config = {
        ProgramArguments = [ "${engramVaultSync}/bin/engram-vault-sync" ];
        EnvironmentVariables = agentEnv;
        StartInterval = 900;
        RunAtLoad = true;
        StandardErrorPath = "${homeDirectory}/.cache/engram-vault-sync.log";
      };
    };

    engram-daily-log = {
      enable = true;
      config = {
        ProgramArguments = [ "${engramDailyLog}/bin/engram-daily-log" ];
        EnvironmentVariables = agentEnv;
        StartInterval = 3600;
        RunAtLoad = true;
        StandardErrorPath = "${homeDirectory}/.cache/engram-daily-log.log";
      };
    };
  };
}

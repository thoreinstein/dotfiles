{ pkgs, lib, config, username, homeDirectory, ... }:
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
  # claude-code 2.1.308+ lost its bundled root store on macOS and needs
  # NODE_EXTRA_CA_CERTS to reach the Anthropic API. sessionVariables reach
  # shells but not launchd agents, so hosts with a CA bundle pass it here for
  # the agents. Drop once upstream ships a fix (2.1.303 and earlier didn't
  # need it).
  options.engram.agents.caBundle = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      CA bundle exported as NODE_EXTRA_CA_CERTS to the engram launchd agents,
      or null on hosts that don't need one.
    '';
  };

  config =
    let
      agentEnv = {
        PATH = agentPath;
      } // lib.optionalAttrs (config.engram.agents.caBundle != null) {
        NODE_EXTRA_CA_CERTS = config.engram.agents.caBundle;
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
    };
}

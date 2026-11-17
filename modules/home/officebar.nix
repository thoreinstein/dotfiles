{ config, inputs, pkgs, ... }:
let
  officebar = inputs.office-daemon.packages.${pkgs.stdenv.hostPlatform.system}.officebar;
in
{
  # officebar: menu bar countdown to the next desk move, and controls for
  # officed (office_daemon's cmd/officebar). On the mini it talks to officed's
  # socket; on the laptop it finds officed with Bonjour and signs requests with
  # the remote token below (the same value as officed's [remote] token).
  launchd.agents.officebar = {
    enable = true;
    config = {
      Label = "com.thoreinstein.officebar";
      ProgramArguments = [ "${officebar}/bin/officebar" ];
      RunAtLoad = true;
      # Restart after a crash, not after Quit in its menu.
      KeepAlive.SuccessfulExit = false;
      ProcessType = "Interactive";
      LimitLoadToSessionType = "Aqua";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/officebar.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/officebar.log";
    };
  };

  sops.secrets.office_remote_token.path = "${config.xdg.configHome}/office/remote-token";
}

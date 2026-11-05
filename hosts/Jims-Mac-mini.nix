{ homeDirectory, ... }:
{
  programs.pi-coding-agent.settings = {
    # strata runs on the gaming PC, which isn't always on.
    defaultProvider = "kimi-coding";
    defaultModel = "k3";
  };

  # officed: the office daemon (github.com/thoreinstein/office_daemon). The
  # binary is not built by nix: it must keep a stable path and signing
  # identifier so macOS's Bluetooth and Local Network grants survive updates.
  # Install or update it with office_daemon's scripts/install.sh.
  launchd.agents.officed = {
    enable = true;
    config = {
      Label = "com.thoreinstein.officed";
      ProgramArguments = [ "${homeDirectory}/.local/bin/officed" ];
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
      ProcessType = "Interactive";
      # Routine logs go to the unified log; this file only catches panics.
      StandardOutPath = "${homeDirectory}/Library/Logs/officed.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/officed.log";
    };
  };
}

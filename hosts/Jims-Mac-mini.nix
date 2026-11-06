{ homeDirectory, pkgs, ... }:
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

  # office-bridge: Google Home switches for officed's modes (office_daemon's
  # bridge/). scripts/install.sh installs it to ~/.local/lib/office-bridge.
  launchd.agents.office-bridge = {
    enable = true;
    config = {
      Label = "com.thoreinstein.office-bridge";
      ProgramArguments = [ "${pkgs.nodejs_24}/bin/node" "${homeDirectory}/.local/lib/office-bridge/index.js" ];
      EnvironmentVariables.MATTER_STORAGE_PATH = "${homeDirectory}/.local/state/office/bridge";
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "${homeDirectory}/Library/Logs/office-bridge.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/office-bridge.log";
    };
  };
}

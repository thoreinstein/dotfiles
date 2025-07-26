{ config, pkgs, lib, inputs, username, hostname, ... }:

{
  # Set the hostname
  networking.hostName = hostname;
  networking.localHostName = hostname;
  networking.computerName = hostname;
  
  # Enable experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Auto upgrade nix package
  nix.package = pkgs.nix;
  
  # Set Git commit hash for darwin-version
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  
  # Set the primary user for system defaults
  system.primaryUser = username;
  
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # System packages (installed globally)
  environment.systemPackages = with pkgs; [
    git
    vim
  ];
  
  # macOS System Settings
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      minimize-to-application = true;
    };
    
    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf"; # Search current folder
      AppleShowAllExtensions = true;
    };
    
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };
  };
  
  # Homebrew integration (for casks and apps not in nixpkgs)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none"; # Don't remove packages
      upgrade = false;
    };
    
    # Taps
    taps = [
    ];
    
    # Homebrew packages (formulas)
    brews = [
      # Add any brew-only packages here
    ];
    
    # Casks for GUI applications
    casks = [
      {
        name = "docker-desktop";
        args = { no_quarantine = true; };
      }
      "ghostty"
      # We'll migrate more casks here as needed
    ];
  };
  
  # User configuration
  users.users."${username}" = {
    name = username;
    home = "/Users/${username}";
  };
  
  # Fix nixbld group ID mismatch
  ids.gids.nixbld = 350;
}

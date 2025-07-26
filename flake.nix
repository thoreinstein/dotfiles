{
  description = "Jim Myers' Darwin system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs: 
  let
    # Machine configurations with usernames
    machines = {
      "carbon" = {
        system = "aarch64-darwin";
        hostname = "carbon";
        username = "myers";
      };
      "silicon" = {
        system = "aarch64-darwin"; # Change to "x86_64-darwin" if Intel
        hostname = "silicon";
        username = "personal-user"; # Replace with actual personal username
      };
      # Work machine - keep actual hostname since it can't be changed
      "CORP-HOSTNAME" = {  # Replace with actual work hostname
        system = "aarch64-darwin"; # Change to "x86_64-darwin" if Intel
        hostname = "CORP-HOSTNAME"; # Replace with actual work hostname  
        username = "work-user"; # Replace with actual work username
      };
    };
    
    # Helper function to create a darwin configuration
    mkDarwinConfig = hostname: machineConfig: 
    let
      # Check if machine-specific config exists
      machineConfigPath = ./nix/machines + "/${hostname}.nix";
      machineConfigExists = builtins.pathExists machineConfigPath;
    in
    nix-darwin.lib.darwinSystem {
      system = machineConfig.system;
      
      modules = [
        ./nix/darwin-configuration.nix
        
        # Optionally include machine-specific configuration
        (if machineConfigExists then machineConfigPath else {})
        
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."${machineConfig.username}" = import ./nix/home.nix;
          home-manager.backupFileExtension = "backup";
          
          # Pass inputs and machine info to home-manager modules
          home-manager.extraSpecialArgs = { 
            inherit inputs;
            inherit (machineConfig) username hostname;
          };
        }
      ];
      
      # Pass inputs and machine info to darwin modules
      specialArgs = { 
        inherit inputs;
        inherit (machineConfig) username hostname;
      };
    };
  in
  {
    # Generate configurations for all machines
    darwinConfigurations = (builtins.mapAttrs mkDarwinConfig machines) // {
      # Convenience output for the flake (defaults to current machine)
      default = self.darwinConfigurations."carbon";
    };
  };
}
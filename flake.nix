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
    username = "myers";
    hostname = "Jims-Mac-mini";
    system = "aarch64-darwin"; # Apple Silicon, use "x86_64-darwin" for Intel
  in
  {
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system;
      
      modules = [
        ./nix/darwin-configuration.nix
        
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."${username}" = import ./nix/home.nix;
          home-manager.backupFileExtension = "backup";
          
          # Pass inputs to home-manager modules
          home-manager.extraSpecialArgs = { inherit inputs username; };
        }
      ];
      
      # Pass inputs to darwin modules
      specialArgs = { inherit inputs username; };
    };
    
    # Convenience output for the flake
    darwinConfigurations.default = self.darwinConfigurations."${hostname}";
  };
}
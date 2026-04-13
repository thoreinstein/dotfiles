{
  description = "Thoreinstein's dotfiles flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Platform management
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim configuration
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Quality Control
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nixvim, git-hooks, ... }@inputs:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkDarwinHost = { system, username }: nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${username} = import ./modules/home;
              sharedModules = [
                nixvim.homeModules.nixvim
              ];
              extraSpecialArgs = {
                inherit username;
                homeDirectory = "/Users/${username}";
              };
            };
          }
        ];
        specialArgs = {
          inherit inputs username;
          homeDirectory = "/Users/${username}";
        };
      };
    in
    {
      # Custom library functions
      lib = import ./lib { inherit (nixpkgs) lib; };

      # Formatter for your nix files, available via 'nix fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # Pre-commit hooks configuration
      checks = forAllSystems (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      });

      # Devshell for bootstrapping
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            packages = with pkgs; [
              codex
              nixpkgs-fmt
              statix
              deadnix
            ];
          };
        });

      # nix-darwin configurations
      darwinConfigurations."Jims-Mac-mini" = mkDarwinHost {
        system = "aarch64-darwin";
        username = "myers";
      };

      darwinConfigurations."mac-1QFL40HG" = mkDarwinHost {
        system = "aarch64-darwin";
        username = "jimmyers";
      };

    };
}

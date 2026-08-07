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
    };

    # Quality Control
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nix-darwin
    , home-manager
    , nixvim
    , git-hooks
    , ...
    }@inputs:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkDarwinHost =
        { hostname
        , system
        , username
        ,
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./modules/darwin
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                backupFileExtension = ".bak";
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username}.imports = [
                  ./modules/home
                  ./hosts/${hostname}.nix
                ];
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
      checks = forAllSystems (
        system:
        {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              statix.enable = true;
              deadnix.enable = true;
            };
          };
        }
        # darwinConfigurations only exist for aarch64-darwin.
        // nixpkgs.lib.optionalAttrs (system == "aarch64-darwin") {
          pi-config =
            let
              pkgs = nixpkgs.legacyPackages.${system};
              # Compare the actual emitted home.file artifacts, not the
              # `settings` / `models` option values in isolation. The
              # module's config is behind `mkIf cfg.enable`, and keys off
              # `cfg.configDir`, so reading the option values directly
              # would stay green even if `enable = false`, `configDir`
              # changed, or `context` were deleted — none of which would
              # actually land in ~/.pi/agent/. Deriving the home.file key
              # from configDir (rather than hardcoding a path) means this
              # fails loudly in all of those cases instead.
              piFile =
                host: user: name:
                let
                  hm = self.darwinConfigurations.${host}.config.home-manager.users.${user};
                in
                hm.home.file."${hm.programs.pi-coding-agent.configDir}/${name}".source;
              mini = name: piFile "Jims-Mac-mini" "myers" name;
              work = name: piFile "mac-1QFL40HG" "jimmyers" name;
            in
            pkgs.runCommand "pi-config-golden" { } ''
              fail=0
              compare() {
                if diff -u "$1" "$2"; then
                  echo "ok   $3"
                else
                  echo "FAIL $3"
                  fail=1
                fi
              }
              compare ${./tests/pi/Jims-Mac-mini/settings.json} \
                      ${mini "settings.json"} "Jims-Mac-mini settings"
              compare ${./tests/pi/Jims-Mac-mini/models.json} \
                      ${mini "models.json"} "Jims-Mac-mini models"
              compare ${./tests/pi/mac-1QFL40HG/settings.json} \
                      ${work "settings.json"} "mac-1QFL40HG settings"
              compare ${./tests/pi/mac-1QFL40HG/models.json} \
                      ${work "models.json"} "mac-1QFL40HG models"
              compare ${./modules/home/pi/AGENTS.md} \
                      ${mini "AGENTS.md"} "Jims-Mac-mini AGENTS.md"
              if [ "$fail" -ne 0 ]; then
                echo "pi config drifted from tests/pi goldens. See tests/pi/README.md to regenerate."
                exit 1
              fi
              touch $out
            '';
        }
      );

      # Devshell for bootstrapping
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            packages = with pkgs; [
              deadnix
              nixpkgs-fmt
              prettier
              statix
            ];
          };
        }
      );

      # nix-darwin configurations
      darwinConfigurations."Jims-Mac-mini" = mkDarwinHost {
        hostname = "Jims-Mac-mini";
        system = "aarch64-darwin";
        username = "myers";
      };

      darwinConfigurations."mac-1QFL40HG" = mkDarwinHost {
        hostname = "mac-1QFL40HG";
        system = "aarch64-darwin";
        username = "jimmyers";
      };

    };
}

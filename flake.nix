{
	description = "janders223 nixes";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
		nixos.url = "github:nixos/nixpkgs/nixos-unstable";
		darwin.url = "github:lnl7/nix-darwin/master";
		darwin.inputs.nixpkgs.follows = "nixpkgs";
		home-manager.url = "github:nix-community/home-manager";
		neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
	};

	outputs = inputs:
	let
		nixpkgs = inputs.nixpkgs;
		neovim-nightly = inputs.neovim-nightly;
		darwinDefaults = { config, pkgs, lib, ... }: {
			imports = [ inputs.home-manager.darwinModules.home-manager ];
		};

		dracula-overlay = super: self: {
			tmuxPlugins.dracula = super.tmuxPlugins.dracule.overrideAttrs {
				src = super.fetchFromGitHub {
					owner = "janders223";
					repo = "tmux";
					rev = "a16ac51c4c561b3c92b074eb0a731e072fd9b3f3";
					sha256 = "1apgrapnqj2vgc579lshag6p8a4njq70987gq6lx4cmgmayvnn4v";
				};
			};
		};

		hasklig-nerd-font = self: super:
		{
			hasklig = super.hasklig.overrideAttrs (old: {
				url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hasklig.zip";

				sha256 = "19wv1k4dbirzkks7d3i0j14zpb0dh87yxxa9bz5b77949bkiyx0a";
			});
		};

		pkgs = import nixpkgs {
			system = "x86_64-darwin";
		};
	in
	{
		darwinConfigurations =
			{
				"OF060VV4A8HTD6F" = inputs.darwin.lib.darwinSystem
				{
					modules = [
						./machines/work.nix
						darwinDefaults
					];
					inputs = { inherit neovim-nightly pkgs; };
				};
			};

			nixosConfigurations.loki = inputs.nixos.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					./machines/loki/configuration.nix
					inputs.home-manager.nixosModules.home-manager
					{
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.users.janders223 = import ./machines/home.nix;
					}
				];
			};

			devShell.x86_64-darwin = import ./shell.nix { inherit pkgs; };
		};
	}

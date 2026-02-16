.PHONY: switch build check fmt

switch:
	home-manager switch --flake .#myers

build:
	nix build .#homeConfigurations.myers.activationPackage --dry-run

check:
	nix flake check

fmt:
	nix fmt

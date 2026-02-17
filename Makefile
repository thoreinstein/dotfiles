.PHONY: switch build check fmt update

switch:
	sudo darwin-rebuild switch --flake '.#Jims-Mac-mini'

build:
	darwin-rebuild build --flake '.#Jims-Mac-mini'

check:
	nix flake check

fmt:
	nix fmt

update:
	nix flake update

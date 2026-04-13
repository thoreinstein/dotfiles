.PHONY: switch build check fmt update

HOST := $(shell scutil --get LocalHostName)

switch:
	sudo darwin-rebuild switch --flake '.#$(HOST)'

build:
	darwin-rebuild build --flake '.#$(HOST)'

check:
	nix flake check

fmt:
	nix fmt

update:
	nix flake update

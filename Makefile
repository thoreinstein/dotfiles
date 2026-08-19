.PHONY: switch build build-all check check-all fmt update

HOST := $(shell scutil --get LocalHostName)

switch:
	sudo darwin-rebuild switch --flake '.#$(HOST)'

build:
	darwin-rebuild build --flake '.#$(HOST)'

build-all:
	darwin-rebuild build --flake '.#Jims-Mac-mini'
	darwin-rebuild build --flake '.#mac-1QFL40HG'

check:
	nix flake check

check-all:
	nix flake check --all-systems

fmt:
	nix fmt

update:
	nix flake update

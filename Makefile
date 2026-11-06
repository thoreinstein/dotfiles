.PHONY: switch bootstrap build build-all check check-all fmt update golden

HOST := $(shell scutil --get LocalHostName)
NIX_FLAKES := --extra-experimental-features 'nix-command flakes'
# Absolute path: before nix-darwin owns /etc/zshrc, a macOS update can reset
# it and drop the installer's PATH setup, and sudo may not see it either.
NIX := /nix/var/nix/profiles/default/bin/nix

switch:
	sudo darwin-rebuild switch --flake '.#$(HOST)'

# First switch on a fresh Mac: darwin-rebuild is not installed and flakes are
# not enabled yet. Runs the darwin-rebuild from flake.lock's nix-darwin input.
bootstrap:
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		echo "darwin-rebuild is already installed; use 'make switch'."; exit 1; \
	fi
	mkdir -p '$(HOME)/Documents/second_brain'
	sudo $(NIX) $(NIX_FLAKES) run --inputs-from . nix-darwin#darwin-rebuild -- \
		switch --flake '.#$(HOST)'

build:
	darwin-rebuild build --flake '.#$(HOST)'

build-all:
	darwin-rebuild build --flake '.#Jims-Mac-mini'
	darwin-rebuild build --flake '.#mac-1QFL40HG'

check:
	nix flake check

# CI-only: --all-systems builds the linux checks too, which needs a linux
# builder on macOS. CI runs it on ubuntu-latest.
check-all:
	nix flake check --all-systems

fmt:
	nix fmt .

golden:
	bash tests/pi/regen.sh

update:
	nix flake update

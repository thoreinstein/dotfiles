#!/usr/bin/env bash
# Regenerate the tests/pi goldens from the evaluated pi config. Run via
# `make golden` after any intentional change to programs.pi-coding-agent
# settings/models/AGENTS.md, then review the diff and run `make check`.
#
# jq comes from the devShell (via direnv) when available; otherwise fall back
# to `nix shell nixpkgs#jq`, which resolves against the registry's nixpkgs, not
# this flake's locked input — fine for formatting output, just not hermetic.
# The `mkdir -p` matters: without it, a third host's first run fails the
# redirect silently rather than erroring loudly.
set -euo pipefail

cd "$(dirname "$0")/../.." || exit 1

if command -v jq >/dev/null 2>&1; then
  JQ=(jq)
else
  JQ=(nix shell nixpkgs#jq -c jq)
fi

for h in "Jims-Mac-mini:myers" "mac-1QFL40HG:jimmyers"; do
  IFS=: read -r host user <<<"$h"
  mkdir -p "tests/pi/$host"
  for a in settings models; do
    nix eval --json ".#darwinConfigurations.$host.config.home-manager.users.$user.programs.pi-coding-agent.$a" |
      "${JQ[@]}" . >"tests/pi/$host/$a.json"
  done
  dir=$(nix eval --raw ".#darwinConfigurations.$host.config.home-manager.users.$user.programs.pi-coding-agent.configDir")
  cp "$(nix eval --raw ".#darwinConfigurations.$host.config.home-manager.users.$user.home.file.\"$dir/AGENTS.md\".source")" \
    "tests/pi/$host/AGENTS.md"
  chmod 644 "tests/pi/$host/AGENTS.md"
done
